# LibrePhotos for YunoHost

[![Integration level](https://dash.yunohost.org/integration/librephotos.svg)](https://dash.yunohost.org/appci/app/librephotos) ![](https://ci-apps.yunohost.org/ci/badges/librephotos.status.svg) ![](https://ci-apps.yunohost.org/ci/badges/librephotos.maintain.svg)  
[![Install librephotos with YunoHost](https://install-app.yunohost.org/install-with-yunohost.svg)](https://install-app.yunohost.org/?app=librephotos)

*[Lire ce readme en français.](./README_fr.md)*

> *This package allows you to install librephotos quickly and simply on a YunoHost server.  
If you don't have YunoHost, please consult [the guide](https://yunohost.org/#/install) to learn how to install it.*

## Overview
LibrePhotos is a Google Photos-like app. It supports automatic classification of faces, grouping photos by date, location, or objects present, and album creation.

**Shipped version:** 2020-04-12

## Screenshots

![](https://raw.githubusercontent.com/LibrePhotos/librephotos/dev/screenshots/mockups_main_fhd.png)

## Demo

* [Official demo](https://demo2.librephotos.com/) User `demo`, password `demo1234`

## Configuration

There is a configuration panel at `https://your-domain.tld/admin`.

## Documentation

 * Official documentation: https://github.com/LibrePhotos/librephotos.

## YunoHost specific features
LDAP is supported. The scan directory of each user is automatically set to `/home/yunohost.multimedia/$username/Picture`.

#### Multi-user support

* Are LDAP and HTTP auth supported? **LDAP only**
* Can the app be used by multiple users? **Yes**

#### Supported architectures


* x86-64 - [![Build Status](https://ci-apps.yunohost.org/ci/logs/librephotos%20%28Apps%29.svg)](https://ci-apps.yunohost.org/ci/apps/librephotos/)
* ARMv8-A - [![Build Status](https://ci-apps-arm.yunohost.org/ci/logs/librephotos%20%28Apps%29.svg)](https://ci-apps-arm.yunohost.org/ci/apps/librephotos/)

## Limitations

* The upstream application has not yet had a stable release, there could be bugs.

## Links

 * Report a bug: https://github.com/YunoHost-Apps/librephotos_ynh/issues
 * Upstream app repository: https://github.com/LibrePhotos/librephotos
 * YunoHost website: https://yunohost.org/

---

## Developer info

**Only if you want to use a testing branch for coding, instead of merging directly into master.**
Please send your pull request to the [testing branch](https://github.com/YunoHost-Apps/librephotos_ynh/tree/testing).

To try the testing branch, please proceed like that.
```
sudo yunohost app install https://github.com/YunoHost-Apps/librephotos_ynh/tree/testing --debug
or
sudo yunohost app upgrade librephotos -u https://github.com/YunoHost-Apps/librephotos_ynh/tree/testing --debug
```
