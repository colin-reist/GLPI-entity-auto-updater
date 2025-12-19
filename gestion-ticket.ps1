# ========================
# CONFIGURATION
# ========================
$Base = "https://support.edu.jura.ch/apirest.php"
$App = "enpPlsELKgxcROGZYtf44ehIx1HJH8T9UBU6dhp7"
$User = "IKnr3ivglWmveMgWGli21s8IXbMDAEKoQLz1rkeV"
# ========================

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

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
            
      $json = $resp.Content | ConvertFrom-Json
      
      if ($json.data.Count -gt 0) {
        foreach ($row in $json.data) {
          # ID du ticket (champ "2" dans les searchOptions par défaut)
          $ticketId = $row."2"
                
          # Détails du ticket
          $ticketResp = Invoke-WebRequest -Uri "$Base/Ticket/$ticketId" -Method GET -Headers @{
            "Session-Token" = $session
            "App-Token"     = $App
          } -UseBasicParsing
                
          $t = $ticketResp.Content | ConvertFrom-Json
                
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
          }
        }
      }
    }
    catch {
      Write-LogMsg "Erreur temporaire dans la boucle : $_"
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