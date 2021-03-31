# LibrePhotos pour YunoHost

[![Niveau d'intégration](https://dash.yunohost.org/integration/librephotos.svg)](https://dash.yunohost.org/appci/app/librephotos) ![](https://ci-apps.yunohost.org/ci/badges/librephotos.status.svg) ![](https://ci-apps.yunohost.org/ci/badges/librephotos.maintain.svg)  
[![Installer librephotos avec YunoHost](https://install-app.yunohost.org/install-with-yunohost.svg)](https://install-app.yunohost.org/?app=librephotos)

*[Read this readme in english.](./README.md)* 

> *Ce package vous permet d'installer LibrePhotos rapidement et simplement sur un serveur YunoHost.  
Si vous n'avez pas YunoHost, consultez [le guide](https://yunohost.org/#/install) pour apprendre comment l'installer.*

## Vue d'ensemble
LibrePhotos est un sercice inspiré par Google Photos. Il prend en charge la classification des visages, le groupement des photos par date, la localisation géographique, ou objets présents, et la création d'albums.

**Version incluse :** 2020-03-29

## Captures d'écran

![](https://raw.githubusercontent.com/LibrePhotos/librephotos/dev/screenshots/mockups_main_fhd.png)

## Démo

* [Démo officielle](https://demo2.librephotos.com/) Utilisatuer `demo`, mot de passe `demo1234`

## Configuration

Il y a un panneau d'administration à `https://votre-domaine.tld/admin`.

## Documentation

 * Documentation officielle : https://github.com/LibrePhotos/librephotos

## Caractéristiques spécifiques YunoHost
LDAP est pris charge. Le dossier de photos de chaque utilisateur est defini comme `/home/yunohost.multimedia/$username/Picture` par défaut.

#### Support multi-utilisateur

* L'authentification LDAP et HTTP est-elle prise en charge ? **Seulement LDAP**
* L'application peut-elle être utilisée par plusieurs utilisateurs ? **Oui**

#### Architectures supportées

* x86-64 - [![Build Status](https://ci-apps.yunohost.org/ci/logs/librephotos%20%28Apps%29.svg)](https://ci-apps.yunohost.org/ci/apps/librephotos/)
* ARMv8-A - [![Build Status](https://ci-apps-arm.yunohost.org/ci/logs/librephotos%20%28Apps%29.svg)](https://ci-apps-arm.yunohost.org/ci/apps/librephotos/)

## Limitations

* L'application d'origine n'a pas encore eu de version stable, il pourrait y avoir des bugs.

## Liens

 * Signaler un bug : https://github.com/YunoHost-Apps/librephotos_ynh/issues
 * Dépôt de l'application principale : https://github.com/LibrePhotos/librephotos
 * Site web YunoHost : https://yunohost.org/

---

## Informations pour les développeurs

**Seulement si vous voulez utiliser une branche de test pour le codage, au lieu de fusionner directement dans la banche principale.**
Merci de faire vos pull request sur la [branche testing](https://github.com/YunoHost-Apps/librephotos_ynh/tree/testing).

Pour essayer la branche testing, procédez comme suit.
```
sudo yunohost app install https://github.com/YunoHost-Apps/librephotos_ynh/tree/testing --debug
ou
sudo yunohost app upgrade librephotos -u https://github.com/YunoHost-Apps/librephotos_ynh/tree/testing --debug
```
