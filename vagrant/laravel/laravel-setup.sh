#!/bin/sh

function error() {
  echo "Error: $@" 1>&2
  exit 1
}

if [ -z "$1" ] || [ ! -z "$2" ]; then
  error "invalid assignment."
fi

[ -e "temp" ] && error "directory 'temp' already exists."

echo "Setup start."
mkdir -p temp/share && \
  cd temp && \
  wget https://raw.githubusercontent.com/shuymn/Misc/master/vagrant/laravel/Vagrantfile 1>/dev/null && \
  wget https://raw.githubusercontent.com/shuymn/Misc/master/vagrant/laravel/prov.sh 1>/dev/null && \
  cd .. && \
  mv temp "$1" && \
  echo "Done."
