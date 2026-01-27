# ========================
# CONFIGURATION
# ========================
# Chargement de la configuration depuis .env
$envFile = Join-Path $PSScriptRoot ".env"
if (Test-Path $envFile) {
  Get-Content $envFile | ForEach-Object {
    if ($_ -match '^\s*([^#=]+?)\s*=\s*(.*)\s*$') {
      $key = $matches[1]
      $val = $matches[2]
      # Nettoyage des quotes éventuelles
      if ($val -match '^"(.*)"$') { $val = $matches[1] }
      elseif ($val -match "^'(.*)'$") { $val = $matches[1] }
      [Environment]::SetEnvironmentVariable($key, $val, "Process")
    }
  }
}
else {
  Write-Host "ERREUR CRITIQUE: Fichier .env manquant !"
  exit 1
}

$Base = $env:GLPI_URL
$App = $env:GLPI_APP_TOKEN
$User = $env:GLPI_USER_TOKEN

if (-not $Base -or -not $App -or -not $User) {
  Write-Host "ERREUR: Configuration incomplète dans le .env"
  exit 1
}

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls11 -bor [Net.SecurityProtocolType]::Tls13

# Ignorer la validation du certificat SSL (pour certificats auto-signés)
if (-not ([System.Management.Automation.PSTypeName]'ServerCertificateValidationCallback').Type) {
  add-type @"
    using System;
    using System.Net;
    using System.Net.Security;
    using System.Security.Cryptography.X509Certificates;
    public class ServerCertificateValidationCallback
    {
        public static void Ignore()
        {
            ServicePointManager.ServerCertificateValidationCallback +=
                delegate
                (
                    Object obj,
                    X509Certificate certificate,
                    X509Chain chain,
                    SslPolicyErrors errors
                )
                {
                    return true;
                };
        }
    }
"@
}
[ServerCertificateValidationCallback]::Ignore()

# Fonction de log simple avec Timestamp
function Write-LogMsg($msg) {
  Write-Host "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - $msg"
}

# --- 1) INIT SESSION ---
Write-LogMsg "Démarrage du service... Connexion à GLPI."
try {
  $init = Invoke-WebRequest -Uri "$Base/initSession" -Method POST -Headers @{
    "App-Token"     = $App
    "Authorization" = "user_token $User"
    "Content-Type"  = "application/json"
  } -Body '{}' -UseBasicParsing
  $session = ($init.Content | ConvertFrom-Json).session_token
}
catch {
  Write-LogMsg "ERREUR CRITIQUE: Impossible d'initialiser la session."
  Write-LogMsg $_
  exit 1
}

if (-not $session) { 
  Write-LogMsg "ERREUR: Pas de session token reçu."
  exit 1 
}

# (Reassurer le profil super-admin)
$bodyProfile = @{ profiles_id = 4 } | ConvertTo-Json
Invoke-WebRequest -Uri "$Base/changeActiveProfile" -Method POST -Headers @{
  "Session-Token" = $session
  "App-Token"     = $App
  "Content-Type"  = "application/json"
} -Body $bodyProfile -UseBasicParsing | Out-Null

Write-LogMsg "Session active. Début de la surveillance."

try {
  # --- 2) BOUCLE INFINIE ---
  while ($true) {
    try {
      # Récupérer les 5 derniers tickets modifiés (sort=19 correspond à date_mod)
      $resp = Invoke-WebRequest -Uri "$Base/search/Ticket?sort=19&order=DESC&range=0-4" -Method GET -Headers @{
        "Session-Token" = $session
        "App-Token"     = $App
      } -UseBasicParsing

      # Vérifier le code de statut (200 OK ou 206 Partial Content sont valides)
      if ($resp.StatusCode -ne 200 -and $resp.StatusCode -ne 206) {
        Write-LogMsg "AVERTISSEMENT: Code HTTP $($resp.StatusCode) reçu lors de la récupération des tickets"
      }

      $json = $resp.Content | ConvertFrom-Json

      if ($json.data.Count -gt 0) {
        # Afficher la liste des IDs récupérés
        $ticketIds = $json.data | ForEach-Object { $_."2" }
        Write-LogMsg "DEBUG: $($json.data.Count) ticket(s) récupéré(s) - IDs: $($ticketIds -join ', ')"

        foreach ($row in $json.data) {
          # ID du ticket (champ "2" dans les searchOptions par défaut)
          $ticketId = $row."2"

          # Détails du ticket
          $ticketResp = Invoke-WebRequest -Uri "$Base/Ticket/$ticketId" -Method GET -Headers @{
            "Session-Token" = $session
            "App-Token"     = $App
          } -UseBasicParsing

          $t = $ticketResp.Content | ConvertFrom-Json

          Write-LogMsg "DEBUG: Ticket #$($t.id) - Lieu: $($t.locations_id) - Entité: $($t.entities_id)"

          # Vérifier si on doit agir
          # Condition : A un lieu ET Lieu != 0
          if ($t.locations_id -and $t.locations_id -ne 0) {

            # Récupérer l'entité attendue pour ce lieu
            $locResp = Invoke-WebRequest -Uri "$Base/Location/$($t.locations_id)" -Method GET -Headers @{
              "Session-Token" = $session
              "App-Token"     = $App
            } -UseBasicParsing
            $loc = $locResp.Content | ConvertFrom-Json
            $targetEntId = [int]$loc.entities_id

            Write-LogMsg "DEBUG: Ticket #$($t.id) - Entité actuelle: $($t.entities_id) - Entité cible: $targetEntId"

            # Si l'entité actuelle est différente de l'entité du lieu -> CORRECTION
            if ([int]$t.entities_id -ne $targetEntId) {
              Write-LogMsg "Ticket #$($t.id) : Entité actuelle $($t.entities_id) != Cible $targetEntId. Correction..."

              $payload = @{
                input = @{
                  id          = $t.id
                  entities_id = $targetEntId
                }
              } | ConvertTo-Json -Depth 5

              Invoke-WebRequest -Uri "$Base/Ticket/$($t.id)" -Method PUT -Headers @{
                "Session-Token" = $session
                "App-Token"     = $App
                "Content-Type"  = "application/json"
              } -Body $payload -UseBasicParsing | Out-Null

              Write-LogMsg "Ticket #$($t.id) : Déplacé vers entité $targetEntId."
            }
            else {
              Write-LogMsg "DEBUG: Ticket #$($t.id) - Entité déjà correcte, aucune action nécessaire"
            }
          }
          else {
            Write-LogMsg "DEBUG: Ticket #$($t.id) - Ignoré (pas de lieu ou lieu = 0)"
          }
        }
      }
    }
    catch {
      $errMsg = $_.Exception.Message

      # Vérifier si c'est une erreur HTTP avec code de statut
      if ($_.Exception.Response) {
        $statusCode = [int]$_.Exception.Response.StatusCode
        $statusDesc = $_.Exception.Response.StatusDescription

        Write-LogMsg "Erreur HTTP $statusCode ($statusDesc) : $errMsg"

        # Erreurs d'autorisation - session peut-être expirée
        if ($statusCode -eq 401 -or $statusCode -eq 403) {
          Write-LogMsg "ERREUR CRITIQUE: Problème d'autorisation détecté. La session pourrait être expirée."
          Write-LogMsg "Arrêt du script pour éviter les erreurs en cascade."
          throw "Session expirée ou accès refusé"
        }
      }
      else {
        Write-LogMsg "Erreur temporaire dans la boucle : $errMsg"
      }
    }

    # Pause de 5 secondes
    Start-Sleep -Seconds 5
  }
}
finally {
  # --- 3) FERMETURE PROPRE ---
  Write-LogMsg "Arrêt du script. Fermeture de session..."
  if ($session) {
    Invoke-WebRequest -Uri "$Base/killSession" -Method GET -Headers @{
      "Session-Token" = $session
      "App-Token"     = $App
    } -UseBasicParsing | Out-Null
  }
}
