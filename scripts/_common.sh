#!/bin/bash

#=================================================
# COMMON VARIABLES
#=================================================

# dependencies used by the app
pkg_dependencies="acl swig libpq-dev postgresql postgresql-contrib postgresql-common curl libopenblas-dev libmagic1 libboost-all-dev libxrender-dev liblapack-dev git bzip2 cmake build-essential libsm6 libglib2.0-0 libgl1-mesa-glx gfortran gunicorn libheif-dev libssl-dev rustc liblzma-dev python3 python3-pip python3-venv imagemagick xsel nodejs npm redis-server libmagickwand-dev libldap2-dev libsasl2-dev ufraw-batch"

#=================================================
# PERSONAL HELPERS
#=================================================

#=================================================
# EXPERIMENTAL HELPERS
#=================================================

#=================================================
# FUTURE OFFICIAL HELPERS
#=================================================

# Install or update the main directory yunohost.multimedia
#
# usage: ynh_multimedia_build_main_dir
ynh_multimedia_build_main_dir () {
        local ynh_media_release="v1.2"
        local checksum="806a827ba1902d6911095602a9221181"

        # Download yunohost.multimedia scripts
        wget -nv https://github.com/YunoHost-Apps/yunohost.multimedia/archive/${ynh_media_release}.tar.gz 2>&1

        # Check the control sum
        echo "${checksum} ${ynh_media_release}.tar.gz" | md5sum -c --status \
                || ynh_die "Corrupt source"

        # Check if the package acl is installed. Or install it.
        ynh_package_is_installed 'acl' \
                || ynh_package_install acl

        # Extract
        mkdir yunohost.multimedia-master
        tar -xf ${ynh_media_release}.tar.gz -C yunohost.multimedia-master --strip-components 1
        ./yunohost.multimedia-master/script/ynh_media_build.sh
}

# Grant write access to multimedia directories to a specified user
#
# usage: ynh_multimedia_addaccess user_name
#
# | arg: user_name - User to be granted write access
ynh_multimedia_addaccess () {
        local user_name=$1
        groupadd -f multimedia
        usermod -a -G multimedia $user_name
}
