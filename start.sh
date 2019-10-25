#!/bin/bash
IPLOCAL="192.168.171.211"

REALM="brservicer.local"
DOMAIN="brservicer"

IPCONTAINER="192.168.171.213"
REDECLIENTE="192.168.171.0/24"
GWCLIENTE="192.168.171.254"

NOMESRV="DC"

function installdocker {
sudo apt update
sudo apt install apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable"
sudo apt update
sudo apt-get install docker-ce docker-ce-cli containerd.io
apt-cache policy docker-ce
echo "{\"iptables\": false}" > /etc/docker/daemon.json
/etc/init.d/docker restart
}

function createimage {
	docker build -t topinfo/samba:latest .
}

function createvirtualnetwork {
docker network create -d macvlan -o parent=br0 \
  --subnet $REDECLIENTE \
  --gateway $GWCLIENTE \
  --aux-address host="$IPLOCAL" \
  nettopinfo
}


if [ ! -f /usr/bin/docker ]; then
	echo -e "Docker não encontrato, instalando Docker\n"
	installdocker
else
	echo -e "Docker já instalado!\n"
fi

imagem=$(docker image ls | grep topinfo)

if [ -z "$imagem" ]; then
	echo -e "Criando imagem para o Container\n"
	createimage
else
	echo -e "Imagem já criada\n"
fi

rede=$(docker network ls | grep nettopinfo)

if [ -z "$rede" ]; then
	echo "Criando rede virtual\n"
        createvirtualnetwork
else
	echo -e "Rede virtual já criada!\n"
fi

topsamba=$(docker ps | grep topsamba)

if [ -z "$topsamba" ]; then
	docker run \
	    -ti \
	    --restart unless-stopped \
	    --name=topsamba \
	    --privileged \
	    --net nettopinfo \
	    --ip $IPCONTAINER \
	    --dns $IPCONTAINER \
	    --dns-search=$REALM \
	    --hostname $NOMESRV \
	    -e SAMBA_DC_REALM=$REALM \
	    -e SAMBA_DC_DOMAIN=$DOMAIN \
	    -e SAMBA_DC_ADMIN_PASSWD='T0p123#$' \
	    -e SAMBA_DC_DNS_BACKEND='BIND9_DLZ' \
	    -e IPSAMBA=$IPCONTAINER \
	    -e NOMESRV=$NOMESRV \
	     "topinfo/samba:latest"
else
	echo -e "Tudo certo!\n"
fi
