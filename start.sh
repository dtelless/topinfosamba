#!/bin/bash

function installdocker {
sudo apt update
sudo apt install apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable"
sudo apt update
apt-cache policy docker-ce
sudo systemctl status docker
}

function createimage {
	docker build -t topinfo/samba:latest .
}




if [ ! -f /usr/bin/docker ]; then
	installdocker
fi

docker create -d --restart unless-stopped \
    --privileged \
    --net nettopinfo \
    --ip 10.0.5.10 \
    -e SAMBA_DC_REALM='brservicer.local' \
    -e SAMBA_DC_DOMAIN='brservicer' \
    -e SAMBA_DC_ADMIN_PASSWD='T0p123#$' \
    -e SAMBA_DC_DNS_BACKEND='BIND9_DLZ' \
#    -v ${PWD}/samba:/samba \
     "topinfo/samba:latest"
