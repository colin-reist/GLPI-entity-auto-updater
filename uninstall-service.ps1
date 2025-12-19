# ==============================================================================
# Désinstallation du service GLPI Ticket Bot
# ==============================================================================

# Vérifier les privilèges administrateur
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "ERREUR: Ce script nécessite des privilèges administrateur." -ForegroundColor Red
    Write-Host "Veuillez relancer PowerShell en tant qu'Administrateur." -ForegroundColor Yellow
    pause
    exit 1
}

$ServiceName = "GLPI_Ticket_Bot"
$NssmPath = "C:\Tools\nssm.exe"

# Vérifier que NSSM existe
if (-not (Test-Path $NssmPath)) {
    Write-Host "ERREUR: NSSM n'est pas trouvé à l'emplacement : $NssmPath" -ForegroundColor Red
    pause
    exit 1
}

# Vérifier si le service existe
$existingService = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
if (-not $existingService) {
    Write-Host "Le service '$ServiceName' n'est pas installé." -ForegroundColor Yellow
    pause
    exit 0
}

Write-Host "Arrêt du service '$ServiceName'..." -ForegroundColor Cyan
& $NssmPath stop $ServiceName
Start-Sleep -Seconds 2

Write-Host "Désinstallation du service..." -ForegroundColor Cyan
& $NssmPath remove $ServiceName confirm

Write-Host "✓ Service désinstallé avec succès" -ForegroundColor Green
pause
