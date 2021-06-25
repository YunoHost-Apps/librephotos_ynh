#!/bin/bash

#=================================================
# COMMON VARIABLES
#=================================================

# dependencies used by the app
pkg_dependencies="libtinfo5 unzip ca-certificates swig libpq-dev postgresql postgresql-contrib postgresql-common ffmpeg libimage-exiftool-perl curl libopenblas-dev libmagic1 libboost-all-dev libxrender-dev liblapack-dev git bzip2 cmake build-essential libsm6 libglib2.0-0 libgl1-mesa-glx gfortran gunicorn libheif-dev libssl-dev rustc liblzma-dev python3 python3-pip python3-venv imagemagick xsel nodejs npm redis-server libmagickwand-dev libldap2-dev libsasl2-dev"

arch="$(dpkg --print-architecture)"
arm64_test=0

if ! (apt-cache -q=0 show ufraw-batch |& grep ': No packages found' &>/dev/null); then
	pkg_dependencies="$pkg_dependencies ufraw-batch"
fi

#=================================================
# PERSONAL HELPERS
#=================================================

function unpack_source {
	ynh_secure_remove "$final_path"
	mkdir -p "$final_path/data_models/"{places365,im2txt}
	ynh_setup_source --source_id="places365" --dest_dir="$final_path/data_models/places365/"
	ynh_setup_source --source_id="im2txt" --dest_dir="$final_path/data_models/im2txt/"
	mkdir -p "$data_path"
	ln -sf "$final_path/data_models" "$data_path/data_models"
	mkdir -p "$data_path/protected_media/"{thumbnails_big,square_thumbnails,square_thumbnails_small,faces}
	mkdir -p "$data_path/data/nextcloud_media"
	mkdir -p "$data_path/matplotlib"

	mkdir -p ~/.cache/torch/hub/checkpoints/
	ynh_setup_source --source_id="resnet152-b121ed2d" --dest_dir="/root/.cache/torch/hub/checkpoints/"

	ynh_setup_source --source_id="backend" --dest_dir="$final_path/backend/"
	ynh_setup_source --source_id="frontend" --dest_dir="$final_path/frontend/"
	ynh_setup_source --source_id="dlib" --dest_dir="$final_path/backend/dlib/"
	if [ "$arch" = "arm64" ] || [ "$arm64_test" -eq 1 ]; then
		export CONDA_DIR="$final_path/backend/conda"
		mkdir -p "$CONDA_DIR"
		if [ "$arch" = "arm64" ]; then
			ynh_setup_source --source_id="miniforge3" --dest_dir="$CONDA_DIR"
			ynh_setup_source --source_id="cmake" --dest_dir="$final_path/backend/cmake/"
		else
			wget -O "${CONDA_DIR}/Miniforge3-4.10.1-4-Linux-aarch64.sh" https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-$(uname)-$(uname -m).sh 2>&1
			ynh_setup_source --source_id="cmake_amd64" --dest_dir="$final_path/backend/cmake/"
		fi
			#ynh_setup_source --source_id="faiss" --dest_dir="$final_path/backend/faiss/"
	fi

	mkdir -p "/var/log/$app"
}

function set_up_backend {
	backend_path="$final_path/backend"
	pushd "$backend_path"
		chown -R $app:$app "$backend_path"
		sudo -u $app python3 -m venv $backend_path/venv
		path_prefix="$backend_path/venv/bin"
		if [ "$arch" = "arm64" ] || [ "$arm64_test" -eq 1 ]; then
			path_prefix="$backend_path/cmake/bin:$CONDA_DIR/condabin:$CONDA_DIR/bin:$path_prefix"
		fi
		local python_path="$path_prefix:$(sudo -u $app bash -c 'echo $PATH')"
		local cache_dir="$backend_path/.cache/pip"
		sudo -u $app env "PATH=$python_path" pip --cache-dir "$cache_dir" install -U wheel pip setuptools 2>&1
		if [ "$arch" = "arm64" ] || [ "$arm64_test" -eq 1 ]; then
			sudo -u $app env "CONDA_DIR=$CONDA_DIR" bash "${CONDA_DIR}/Miniforge3-4.10.1-4-Linux-aarch64.sh" -bu -p "${CONDA_DIR}"
			sudo -u $app env "PATH=$python_path" pip --cache-dir "$cache_dir" install -U torch==1.8.1 torchvision==0.9.1 -f https://torch.maku.ml/whl/stable.html 2>&1
			sudo -u $app env "PATH=$python_path" conda install -y numpy psycopg2 cython pandas scikit-learn=0.24.1 scikit-image=0.18.1 spacy=2.3.5 gevent=20.12.1 matplotlib=3.3.2 faiss-cpu==1.7.0
			#pushd "$backend_path/faiss"
			#	sudo -u $app env "PATH=$python_path" cmake -B build . -DFAISS_ENABLE_GPU=OFF -DFAISS_ENABLE_PYTHON=ON -DFAISS_OPT_LEVEL=generic
			#	sudo -u $app env "PATH=$python_path" make -C build -j faiss
			#	sudo -u $app env "PATH=$python_path" make -C build -j swigfaiss
			#	cd "build/faiss/python"
			#	sudo -u $app env "PATH=$python_path" python setup.py install
			#popd
			sed -i "/spacy==2.3.2/d" "$backend_path/requirements.txt"
			sed -i "/sklearn==0.0/d" "$backend_path/requirements.txt"
			sed -i "/gevent==20.9.0/d" "$backend_path/requirements.txt"
			sed -i "/scipy==1.5.3/d" "$backend_path/requirements.txt"
			sed -i "s/pytz==2020.1/pytz>=2021.1/" "$backend_path/requirements.txt"
			sed -i "s/Pillow==8.1.0/Pillow>=8.1.2/" "$backend_path/requirements.txt"
			sed -i "/faiss-cpu==1.7.0/d" "$backend_path/requirements.txt"
		else
			sudo -u $app env "PATH=$python_path" pip --cache-dir "$cache_dir" install -U torch==1.8.0+cpu torchvision==0.9.0+cpu -f https://download.pytorch.org/whl/torch_stable.html 2>&1
		fi
		pushd "$backend_path/dlib"
			sudo -u $app env "PATH=$python_path" python setup.py install 2>&1
		popd
		sudo -u $app env "PATH=$python_path" pip --cache-dir "$cache_dir" install -U --requirement "$backend_path/requirements.txt" 2>&1
		sudo -u $app env "PATH=$python_path" pip --cache-dir "$cache_dir" install -U --requirement "$backend_path/requirements-ynh.txt" 2>&1
		sudo -u $app env "PATH=$python_path" python -m spacy download en_core_web_sm 2>&1
		#if [ "$arch" = "arm64" ] || [ "$arm64_test" -eq 1 ]; then
			#sudo -u $app unzip "$CONDA_DIR/lib/python3.8/site-packages/"faiss*.egg -d "$CONDA_DIR/lib/python3.8/site-packages/"
		#fi
		chown -R root:root "$backend_path"
	popd
}

function install_dlib {
	pushd "$backend_path/dlib"
		sudo -u $app "$backend_path/venv/bin/python" setup.py install 2>&1
	popd
}

function set_node_vars {
	ynh_exec_warn_less ynh_install_nodejs --nodejs_version=13
	ynh_use_nodejs
	node_PATH=$nodejs_path:$(sudo -u $app sh -c 'echo $PATH')

}

function set_up_frontend {
	set_node_vars
	frontend_path=$final_path/frontend
	pushd $final_path/frontend
		chown -R $app:$app $frontend_path
		sudo -u $app touch $frontend_path/.yarnrc
		sudo -u $app env "PATH=$node_PATH" yarn --cache-folder $frontend_path/yarn-cache --use-yarnrc $frontend_path/.yarnrc install 2>&1
		sudo -u $app env "PATH=$node_PATH" yarn --cache-folder $frontend_path/yarn-cache --use-yarnrc $frontend_path/.yarnrc run build 2>&1
		sudo -u $app env "PATH=$node_PATH" yarn --cache-folder $frontend_path/yarn-cache --use-yarnrc $frontend_path/.yarnrc add serve 2>&1
		chown -R root:root $frontend_path
	popd
}

function add_configuations {
	secret_key=$(ynh_app_setting_get --app=$app --key=secret_key)

	if [ -z $secret_key ]; then
		secret_key=$(ynh_string_random -l 64)
		ynh_app_setting_set --app=$app --key=secret_key --value=$secret_key
	fi

	ynh_add_config --template="librephotos.env" --destination="$final_path/librephotos.env"
}

function upgrade_db {
	pushd "$final_path/backend"
		chown -R $app:$app "$final_path/backend"
		chown -R $app:$app "/var/log/$app"
		sudo -u $app bash -c "
			set -a
			export PATH=\"$path_prefix:"'$PATH'"\"
			source \"$final_path\"/librephotos.env
			python3 manage.py showmigrations
			python3 manage.py migrate 
			python3 manage.py showmigrations
		" 2>&1
	popd
	set_permissions
}

function set_permissions {
	chown -R root:$app "$final_path"
	chmod -R g=u,g-w,o-rwx "$final_path"
	chown -R $app:$app "$data_path"
	chmod -R g=u,g-w,o-rwx "$data_path"
	chown -R $app:$app "$final_path/data_models"
	chown -R $app:$app "/var/log/$app"
	chmod -R g-w,o-rwx "/var/log/$app"
	setfacl -n -m user:www-data:rx "$data_path"
	setfacl -nR -m u:www-data:rx -m d:u:www-data:rx "$data_path/protected_media" "$data_path/data" "$data_path/data/nextcloud_media"
}

function set_up_logrotate {
	ynh_use_logrotate --logfile="/var/log/$app/command_build_similarity_index.log" --specific_user="$app/$app" --non_append
	ynh_use_logrotate --logfile="/var/log/$app/gunicorn_django.log" --specific_user="$app/$app"
	ynh_use_logrotate --logfile="/var/log/$app/image_similarity.log" --specific_user="$app/$app"
	ynh_use_logrotate --logfile="/var/log/$app/ownphotos.log" --specific_user="$app/$app"
}

#=================================================
# EXPERIMENTAL HELPERS
#=================================================

#=================================================
# FUTURE OFFICIAL HELPERS
#=================================================
