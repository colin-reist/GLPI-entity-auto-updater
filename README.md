# 🎫 GLPI Entity Auto-Updater

<div align="center">

**Service Windows automatisé pour maintenir la cohérence des entités GLPI**

[![PowerShell](https://img.shields.io/badge/PowerShell-5.1+-blue.svg)](https://docs.microsoft.com/en-us/powershell/)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![GLPI](https://img.shields.io/badge/GLPI-API%20REST-orange.svg)](https://github.com/glpi-project/glpi)

[Fonctionnalités](#-fonctionnalités) • [Installation](#-installation-rapide) • [Wiki](../../wiki) • [Contribution](#-contribution)

</div>

---

## 📖 À propos

**GLPI Entity Auto-Updater** est un service Windows qui surveille automatiquement les tickets GLPI et corrige leur entité (`entities_id`) en fonction de leur localisation (`locations_id`). 

### 🎯 Problème résolu

Dans GLPI, lorsqu'un ticket est créé avec une localisation spécifique, l'entité associée n'est pas toujours correctement assignée. Ce service résout ce problème en :
- Surveillant continuellement les tickets récemment modifiés
- Détectant les incohérences entre l'entité du ticket et l'entité de sa localisation
- Corrigeant automatiquement l'entité du ticket

---

## ✨ Fonctionnalités

- 🔄 **Surveillance continue** : Vérifie les tickets toutes les 5 secondes
- 🎯 **Correction automatique** : Met à jour l'entité selon la localisation
- 📝 **Logging complet** : Journalisation de toutes les actions et erreurs
- 🚀 **Démarrage automatique** : S'exécute comme service Windows au boot
- 🛡️ **Gestion d'erreurs robuste** : Redémarrage automatique en cas de problème
- ⚙️ **Installation automatisée** : Scripts d'installation/désinstallation inclus

---

## 🚀 Installation rapide

### Prérequis

- Windows 10/11 ou Windows Server
- PowerShell 5.1 ou supérieur
- [NSSM](https://nssm.cc/) (Non-Sucking Service Manager)
- Droits administrateur
- Accès à l'API REST GLPI avec token utilisateur et application

### Installation en 3 étapes

1. **Télécharger NSSM** et placer `nssm.exe` dans `C:\Tools\`

2. **Cloner ou télécharger ce repository**
   ```powershell
   git clone https://github.com/votre-username/GLPI-entity-auto-updater.git
   cd GLPI-entity-auto-updater
   ```

3. **Configurer et installer** (en tant qu'Administrateur)
   ```powershell
   # Éditer gestion-ticket.ps1 pour ajouter vos tokens API GLPI
   # Puis installer le service :
   .\install-service.ps1
   ```

> 📚 **Documentation détaillée** : Consultez le [Wiki](../../wiki) pour :
> - Guide d'installation pas à pas
> - Configuration avancée
> - Gestion du service
> - Dépannage complet
> - Structure de l'API GLPI

---

## 🔧 Configuration

Avant la première utilisation, éditez `gestion-ticket.ps1` pour configurer vos accès API :

```powershell
$Base = "https://votre-instance-glpi.com/apirest.php"
$App = "votre_app_token"
$User = "votre_user_token"
```

> ⚠️ **Sécurité** : Ne commitez jamais vos tokens dans le dépôt Git !

---

## 📊 Utilisation

Une fois installé, le service fonctionne automatiquement en arrière-plan.

### Commandes de gestion

```powershell
# Vérifier le statut
Get-Service GLPI_Ticket_Bot

# Démarrer/Arrêter/Redémarrer
Start-Service GLPI_Ticket_Bot
Stop-Service GLPI_Ticket_Bot
Restart-Service GLPI_Ticket_Bot

# Consulter les logs en temps réel
Get-Content .\logs\service-output.log -Wait -Tail 20
```

### Désinstallation

```powershell
.\uninstall-service.ps1
```

---

## 📁 Structure du projet

```
GLPI-entity-auto-updater/
├── gestion-ticket.ps1       # Script principal de surveillance
├── install-service.ps1      # Installation automatique du service
├── uninstall-service.ps1    # Désinstallation du service
├── check-service.ps1        # Vérification rapide du statut
├── README.md                # Ce fichier
├── .gitignore
└── logs/                    # Logs du service (créé automatiquement)
    ├── service-output.log
    └── service-error.log
```

---

## 🤝 Contribution

Les contributions sont les bienvenues ! N'hésitez pas à :

- 🐛 Signaler des bugs
- 💡 Proposer de nouvelles fonctionnalités
- 🔧 Soumettre des pull requests
- 📖 Améliorer la documentation

---

## 📝 License

Ce projet est sous licence MIT. Voir le fichier `LICENSE` pour plus de détails.

---

## 🙏 Remerciements

- [GLPI Project](https://glpi-project.org/) pour l'excellent système de gestion d'assistance
- [NSSM](https://nssm.cc/) pour la gestion simple des services Windows

---

<div align="center">

**Fait avec ❤️ pour simplifier la gestion GLPI**

[⬆ Retour en haut](#-glpi-entity-auto-updater)

</div>
