#!/bin/bash

#=================================================
# COMMON VARIABLES
#=================================================

# dependencies used by the app
pkg_dependencies="acl swig libpq-dev postgresql postgresql-contrib postgresql-common curl libopenblas-dev libmagic1 libboost-all-dev libxrender-dev liblapack-dev git bzip2 cmake build-essential libsm6 libglib2.0-0 libgl1-mesa-glx gfortran gunicorn libheif-dev libssl-dev rustc liblzma-dev python3 python3-pip python3-venv imagemagick xsel nodejs npm redis-server libmagickwand-dev libldap2-dev libsasl2-dev ufraw-batch"

#=================================================
# PERSONAL HELPERS
#=================================================

function unpack_source {
	mkdir -p $final_path/data_models/{places365,im2txt}
	ynh_setup_source --source_id="places365_model" --dest_dir="$final_path/data_models/places365/model/"
	ynh_setup_source --source_id="im2txt_model" --dest_dir="$final_path/data_models/im2txt/model/"
	ynh_setup_source --source_id="im2txt_data" --dest_dir="$final_path/data_models/im2txt/data/"
	mkdir -p $data_path
	ln -sf "$final_path/data_models" "$data_path/data_models"
	mkdir -p $data_path/protected_media/{thumbnails_big,square_thumbnails,square_thumbnails_small,faces}
	mkdir -p $data_path/data/nextcloud_media
	mkdir -p $data_path/matplotlib

	mkdir -p ~/.cache/torch/hub/checkpoints/
	ynh_setup_source --source_id="resnet152-b121ed2d" --dest_dir="/root/.cache/torch/hub/checkpoints/"

	ynh_setup_source --source_id="backend" --dest_dir="$final_path/backend/"
	ynh_setup_source --source_id="frontend" --dest_dir="$final_path/frontend/"
	ynh_setup_source --source_id="linux" --dest_dir="$final_path/linux/"
	mkdir -p "$final_path/bin"
	mv -f "$final_path/linux/ressources/bin/"* "$final_path/bin"
	ynh_secure_remove --file="$final_path/linux"

	mkdir -p /var/log/$app
}

function set_up_virtualenv {
	backend_path=$final_path/backend
	pushd $backend_path || ynh_die
		chown -R $app:$app $backend_path
		sudo -u $app python3 -m venv $backend_path/venv
		sudo -u $app $backend_path/venv/bin/pip --cache-dir $backend_path/.cache/pip install -U wheel pip setuptools 2>&1
		sudo -u $app $backend_path/venv/bin/pip --cache-dir $backend_path/.cache/pip install -U torch==1.7.1+cpu torchvision==0.8.2+cpu -f https://download.pytorch.org/whl/torch_stable.html 2>&1
		sudo -u $app $backend_path/venv/bin/pip --cache-dir $backend_path/.cache/pip install -U --install-option="--no" --install-option="DLIB_USE_CUDA" --install-option="--no" --install-option="USE_AVX_INSTRUCTIONS" --install-option="--no" --install-option="USE_SSE4_INSTRUCTIONS" dlib 2>&1
		sudo -u $app $backend_path/venv/bin/pip --cache-dir $backend_path/.cache/pip install -U --requirement $backend_path/requirements.txt 2>&1
		sudo -u $app $backend_path/venv/bin/pip --cache-dir $backend_path/.cache/pip install -U --requirement $backend_path/requirements-ynh.txt 2>&1
		sudo -u $app $backend_path/venv/bin/python -m spacy download en_core_web_sm 2>&1
		chown -R root:root $backend_path
	popd || ynh_die
}

function set_node_vars {
	ynh_exec_warn_less ynh_install_nodejs --nodejs_version=10
	ynh_use_nodejs
	node_PATH=$nodejs_path:$(sudo -u $app sh -c 'echo $PATH')

}

function set_up_frontend {
	set_node_vars
	frontend_path=$final_path/frontend
	pushd $final_path/frontend || ynh_die
		chown -R $app:$app $frontend_path
		sudo -u $app touch $frontend_path/.yarnrc
		sudo -u $app env "PATH=$node_PATH" yarn --cache-folder $frontend_path/yarn-cache --use-yarnrc $frontend_path/.yarnrc install 2>&1
		sudo -u $app env "PATH=$node_PATH" yarn --cache-folder $frontend_path/yarn-cache --use-yarnrc $frontend_path/.yarnrc run build 2>&1
		sudo -u $app env "PATH=$node_PATH" yarn --cache-folder $frontend_path/yarn-cache --use-yarnrc $frontend_path/.yarnrc add serve 2>&1
		chown -R root:root $frontend_path
	popd || ynh_die
}

function add_configuations {
	secret_key=$(ynh_app_setting_get --app=$app --key=secret_key)

	if [ -z $secret_key ]; then
		secret_key=$(ynh_string_random -l 64)
		ynh_app_setting_set --app=$app --key=secret_key --value=$secret_key
	fi

	ynh_add_config --template="librephotos.env" --destination="$final_path/librephotos.env"

	for file in $final_path/bin/*; do
		ynh_replace_string -m '#!/usr/bin/env bash' -r "#!/usr/bin/env bash\nsource $final_path/librephotos.env" -f $file
		echo "$(uniq $file)" > $file
		ynh_replace_string -m "source $final_path/librephotos.env" -r "source $final_path/librephotos.env\nexport PATH=\$NODEJS_PATH:\$PATH" -f $file
		echo "$(uniq $file)" > $file
		ynh_replace_string -m "/usr/lib/librephotos" -r "$final_path" -f $file
		ynh_replace_string -m 3000 -r '$httpPort' -f $file
		ynh_replace_string -m 8001 -r '$BACKEND_PORT' -f $file
		ynh_replace_string -m 8002 -r '$IMAGE_SIMILARITY_SERVER_PORT' -f $file
		ynh_replace_string -m "/etc/librephotos" -r $final_path -f $file
		ynh_replace_string -m "librephotos-backend.env" -r "librephotos.env" -f $file
		ynh_replace_special_string -m 'su - -s $(which bash) librephotos << EOF' -r '' -f $file
		ynh_replace_special_string -m 'EOF' -r '' -f $file
		ynh_replace_string -m "python3" -r "$backend_path/venv/bin/python3" -f $file
		ynh_replace_string -m "gunicorn --workers" -r "$backend_path/venv/bin/gunicorn --workers" -f $file
		ynh_replace_string -m "$backend_path/venv/bin/$backend_path/venv/bin/python" -r "$backend_path/venv/bin/python" -f $file
		ynh_replace_string -m "$backend_path/venv/bin/$backend_path/venv/bin/gunicorn --workers" -r "$backend_path/venv/bin/gunicorn --workers" -f $file
		ynh_replace_string -m 'npm install' -r " " -f $file
		ynh_replace_string -m 'npm' -r "yarn" -f $file
	done
}

function set_permissions {
	chown -R root:$app $final_path
	chmod -R g=u,g-w,o-rwx $final_path
	chown -R $app:$app $data_path
	chmod -R g=u,g-w,o-rwx $data_path
	chown -R $app:$app $final_path/data_models
	chown -R $app:$app /var/log/$app
	chmod -R g-w,o-rwx /var/log/$app
	setfacl -n -m user:www-data:rx $data_path
	setfacl -n -R -m user:www-data:rx -m default:user:www-data:rx $data_path/protected_media $data_path/data $data_path/data/nextcloud_media
}

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
