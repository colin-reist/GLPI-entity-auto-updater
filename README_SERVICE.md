# Service Windows - GLPI Ticket Bot

Ce document explique comment installer le script `gestion-ticket.ps1` en tant que **service Windows** qui s'exécutera automatiquement au démarrage de la machine.

## 📋 Prérequis

1. **Télécharger NSSM** (Non-Sucking Service Manager)
   - Télécharger depuis : [https://nssm.cc/release/nssm-2.24.zip](https://nssm.cc/release/nssm-2.24.zip)
   - Extraire le fichier `nssm.exe` (version win64) dans `C:\Tools\nssm.exe`
   - ⚠️ Le dossier `C:\Tools` doit exister (créez-le si nécessaire)

2. **Privilèges Administrateur**
   - L'installation nécessite PowerShell en mode Administrateur

---

## 🚀 Installation Automatique (Recommandé)

Le projet inclut un script d'installation automatisé qui configure tout pour vous.

### Étapes :

1. **Ouvrir PowerShell en Administrateur**
   - Clic droit sur PowerShell → "Exécuter en tant qu'administrateur"

2. **Naviguer vers le dossier du projet**
   ```powershell
   cd "C:\Users\reist\Documents\GitHub\WebHook-GLPI"
   ```

3. **Exécuter le script d'installation**
   ```powershell
   .\install-service.ps1
   ```

Le script va automatiquement :
- ✅ Vérifier les prérequis (NSSM, droits admin, etc.)
- ✅ Créer un dossier `logs` pour les fichiers de log
- ✅ Configurer le service avec démarrage automatique
- ✅ Configurer la rotation des logs
- ✅ Configurer le redémarrage automatique en cas d'erreur
- ✅ Démarrer le service

---

## 🔧 Installation Manuelle (Alternative)

Si vous préférez installer manuellement avec NSSM :

### 1. Installer le service
Ouvrir PowerShell en **Administrateur** :
```powershell
C:\Tools\nssm.exe install GLPI_Ticket_Bot
```

### 2. Configurer dans la fenêtre NSSM

**Onglet Application :**
- **Path**: `C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe`
- **Startup directory**: `C:\Users\reist\Documents\GitHub\WebHook-GLPI`
- **Arguments**: `-ExecutionPolicy Bypass -NoProfile -File "C:\Users\reist\Documents\GitHub\WebHook-GLPI\gestion-ticket.ps1"`

**Onglet Details :**
- **Display name**: `Bot GLPI Ticket Fix`
- **Description**: `Surveille et corrige l'entité des tickets GLPI selon leur lieu.`
- **Startup type**: `Automatic`

**Onglet I/O (Logs) :**
- **Output (stdout)**: `C:\Users\reist\Documents\GitHub\WebHook-GLPI\logs\service-output.log`
- **Error (stderr)**: `C:\Users\reist\Documents\GitHub\WebHook-GLPI\logs\service-error.log`

**Onglet Exit actions :**
- **Restart application**: Cocher pour redémarrage automatique
- **Delay restart by**: `5000` ms

Cliquer sur **Install service**.

### 3. Démarrer le service
```powershell
Start-Service GLPI_Ticket_Bot
```

---

## 📊 Gestion du Service

### Commandes PowerShell

```powershell
# Vérifier le statut
Get-Service GLPI_Ticket_Bot

# Démarrer le service
Start-Service GLPI_Ticket_Bot

# Arrêter le service
Stop-Service GLPI_Ticket_Bot

# Redémarrer le service
Restart-Service GLPI_Ticket_Bot

# Voir les détails
Get-Service GLPI_Ticket_Bot | Format-List *
```

### Désinstallation

**Option 1 - Script automatique :**
```powershell
.\uninstall-service.ps1
```

**Option 2 - Manuel :**
```powershell
# Arrêter le service
C:\Tools\nssm.exe stop GLPI_Ticket_Bot

# Désinstaller
C:\Tools\nssm.exe remove GLPI_Ticket_Bot confirm
```

---

## 📁 Fichiers de Logs

Les logs sont automatiquement écrits dans le dossier `logs/` :

- **`logs/service-output.log`** : Sortie standard (logs normaux du script)
- **`logs/service-error.log`** : Erreurs

### Visualiser les logs en temps réel
```powershell
# Logs normaux
Get-Content .\logs\service-output.log -Wait -Tail 20

# Logs d'erreurs
Get-Content .\logs\service-error.log -Wait -Tail 20
```

---

## 🔄 Redémarrage Automatique

Le service est configuré pour :
- ✅ Démarrer automatiquement au démarrage de Windows
- ✅ Redémarrer automatiquement en cas d'erreur (après 5 secondes)
- ✅ Se fermer proprement lors de l'arrêt de Windows

---

## ⚠️ Dépannage

### Le service ne démarre pas
1. Vérifiez les logs dans `logs/service-error.log`
2. Testez le script manuellement :
   ```powershell
   .\gestion-ticket.ps1
   ```
3. Vérifiez les identifiants API dans le script

### Le service démarre mais s'arrête immédiatement
- Vérifiez que la connexion à l'API GLPI fonctionne
- Vérifiez que `$App` et `$User` dans `gestion-ticket.ps1` sont corrects

### Logs trop volumineux
Les logs s'accumulent dans les fichiers. Pour nettoyer :
```powershell
# Vider les logs
Clear-Content .\logs\service-output.log
Clear-Content .\logs\service-error.log
```

---

## 📝 Structure des Fichiers

```
WebHook-GLPI/
├── gestion-ticket.ps1      # Script principal
├── install-service.ps1     # Installation automatique
├── uninstall-service.ps1   # Désinstallation
├── README_SERVICE.md       # Ce fichier
└── logs/                   # Créé automatiquement
    ├── service-output.log  # Logs de sortie
    └── service-error.log   # Logs d'erreurs
```

---

## ✅ Vérification de l'Installation

Après installation, vérifiez que tout fonctionne :

1. **Vérifier le statut du service**
   ```powershell
   Get-Service GLPI_Ticket_Bot
   ```
   → Devrait afficher : `Status : Running`

2. **Vérifier les logs**
   ```powershell
   Get-Content .\logs\service-output.log -Tail 10
   ```
   → Devrait afficher les messages de démarrage et de surveillance

3. **Tester le redémarrage**
   ```powershell
   Restart-Computer
   ```
   → Après le redémarrage, le service devrait être automatiquement en cours d'exécution
