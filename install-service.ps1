# ==============================================================================
# Installation automatique du service GLPI Ticket Bot
# ==============================================================================

# Vérifier les privilèges administrateur
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "ERREUR: Ce script nécessite des privilèges administrateur." -ForegroundColor Red
    Write-Host "Veuillez relancer PowerShell en tant qu'Administrateur." -ForegroundColor Yellow
    pause
    exit 1
}

# Configuration
$ServiceName  = "GLPI_Ticket_Bot"
$DisplayName  = "GLPI_Ticket_Bot"
$Description  = "Surveille et corrige l'entité des tickets GLPI selon leur lieu."
$ScriptPath   = Join-Path $PSScriptRoot "gestion-ticket.ps1"
$LogDirectory = Join-Path $PSScriptRoot "logs"
$NssmPath     = "C:\Tools\nssm.exe"

# Vérifier que le script existe
if (-not (Test-Path $ScriptPath)) {
    Write-Host "ERREUR: Le script $ScriptPath n'existe pas." -ForegroundColor Red
    pause
    exit 1
}

# Créer le dossier logs s'il n'existe pas
if (-not (Test-Path $LogDirectory)) {
    New-Item -ItemType Directory -Path $LogDirectory -Force | Out-Null
    Write-Host "✓ Dossier logs créé : $LogDirectory" -ForegroundColor Green
}

# Vérifier que NSSM existe
if (-not (Test-Path $NssmPath)) {
    Write-Host "ERREUR: NSSM n'est pas trouvé à l'emplacement : $NssmPath" -ForegroundColor Red
    Write-Host ""
    Write-Host "Veuillez télécharger NSSM depuis https://nssm.cc/release/nssm-2.24.zip" -ForegroundColor Yellow
    Write-Host "et extraire nssm.exe (version win64) dans C:\Tools" -ForegroundColor Yellow
    pause
    exit 1
}

# Vérifier si le service existe déjà
$existingService = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
if ($existingService) {
    Write-Host "⚠ Le service '$ServiceName' existe déjà." -ForegroundColor Yellow
    $response = Read-Host "Voulez-vous le désinstaller et le réinstaller ? (O/N)"
    if ($response -eq 'O' -or $response -eq 'o') {
        Write-Host "Arrêt du service..." -ForegroundColor Cyan
        & $NssmPath stop $ServiceName | Out-Null
        Start-Sleep -Seconds 2

        Write-Host "Désinstallation du service..." -ForegroundColor Cyan
        & $NssmPath remove $ServiceName confirm | Out-Null
        Start-Sleep -Seconds 2
        Write-Host "✓ Service désinstallé" -ForegroundColor Green
    }
    else {
        Write-Host "Installation annulée." -ForegroundColor Yellow
        pause
        exit 0
    }
}  # <-- IMPORTANT : fermeture du if ($existingService)

# Installation du service
Write-Host ""
Write-Host "Installation du service '$DisplayName'..." -ForegroundColor Cyan

# Installer le service avec NSSM
& $NssmPath install $ServiceName "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" | Out-Null

# Configurer les arguments
$arguments = "-ExecutionPolicy Bypass -NoProfile -File `"$ScriptPath`""
& $NssmPath set $ServiceName AppParameters $arguments | Out-Null

# Configurer le répertoire de travail
& $NssmPath set $ServiceName AppDirectory $PSScriptRoot | Out-Null

# Configurer les détails du service
& $NssmPath set $ServiceName DisplayName $DisplayName | Out-Null
& $NssmPath set $ServiceName Description $Description | Out-Null

# Configurer le démarrage automatique
& $NssmPath set $ServiceName Start SERVICE_AUTO_START | Out-Null

# Configurer les logs (rediriger stdout et stderr)
$stdoutLog = Join-Path $LogDirectory "service-output.log"
$stderrLog = Join-Path $LogDirectory "service-error.log"
& $NssmPath set $ServiceName AppStdout $stdoutLog | Out-Null
& $NssmPath set $ServiceName AppStderr $stderrLog | Out-Null

# (Optionnel) Append au lieu d'écraser
& $NssmPath set $ServiceName AppStdoutCreationDisposition 4 | Out-Null
& $NssmPath set $ServiceName AppStderrCreationDisposition 4 | Out-Null

# Redémarrage automatique en cas d'erreur
& $NssmPath set $ServiceName AppExit Default Restart | Out-Null
& $NssmPath set $ServiceName AppRestartDelay 5000 | Out-Null

# Arrêt propre
& $NssmPath set $ServiceName AppStopMethodSkip 0 | Out-Null
& $NssmPath set $ServiceName AppStopMethodConsole 1500 | Out-Null
& $NssmPath set $ServiceName AppStopMethodWindow 1500 | Out-Null
& $NssmPath set $ServiceName AppStopMethodThreads 1500 | Out-Null

# IMPORTANT : ton NSSM ne supporte pas AppKillProcessTree -> on ne le met pas

Write-Host "✓ Service installé avec succès" -ForegroundColor Green

# Démarrer le service
Write-Host ""
Write-Host "Démarrage du service..." -ForegroundColor Cyan
& $NssmPath start $ServiceName | Out-Null

Start-Sleep -Seconds 2

# Vérifier le statut
$serviceStatus = Get-Service -Name $ServiceName
if ($serviceStatus.Status -eq 'Running') {
    Write-Host "✓ Service démarré avec succès !" -ForegroundColor Green
    Write-Host ""
    Write-Host "======================================" -ForegroundColor Cyan
    Write-Host "INFORMATIONS DU SERVICE" -ForegroundColor Cyan
    Write-Host "======================================" -ForegroundColor Cyan
    Write-Host "Nom du service : $ServiceName"
    Write-Host "Nom d'affichage : $DisplayName"
    Write-Host "Statut : $($serviceStatus.Status)"
    Write-Host "Type de démarrage : Automatique"
    Write-Host ""
    Write-Host "Logs :" -ForegroundColor Yellow
    Write-Host "  - Sortie standard : $stdoutLog"
    Write-Host "  - Erreurs : $stderrLog"
    Write-Host ""
    Write-Host "Commandes utiles :" -ForegroundColor Yellow
    Write-Host "  - Arrêter : Stop-Service $ServiceName"
    Write-Host "  - Démarrer : Start-Service $ServiceName"
    Write-Host "  - Redémarrer : Restart-Service $ServiceName"
    Write-Host "  - Statut : Get-Service $ServiceName"
    Write-Host "  - Désinstaller : $NssmPath remove $ServiceName confirm"
    Write-Host ""
}
else {
    Write-Host "⚠ Le service est installé mais n'a pas démarré." -ForegroundColor Yellow
    Write-Host "Statut : $($serviceStatus.Status)" -ForegroundColor Yellow
    Write-Host "Vérifiez les logs dans : $LogDirectory" -ForegroundColor Yellow
}

pause
