#!/bin/bash
IPLOCAL=""
IPSAMBA="192.168.171.212"

REALM="brservicer.local"
DOMAIN="brservicer"

IPCONTAINER="10.0.5.10"
REDEDOCKER="10.0.5.0/24"

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
docker network create --subnet=$REDEDOCKER -o "com.docker.network.bridge.host_binding_ipv4"="0.0.0.0" -o "com.docker.network.bridge.enable_icc"="true" -o "com.docker.network.driver.mtu"="1500" -o "com.docker.network.bridge.name"="lxcbr1" -o "com.docker.network.bridge.enable_ip_masquerade"="true" nettopinfo
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

firewallDNAT=$(iptables -L -t nat | grep DNAT | grep $IPCONTAINER)
firewallSNAT=$(iptables -L -t nat | grep SNAT | grep $IPCONTAINER)

if [ -z "$firewallDNAT" ] && [ -z "$firewallSNAT"]; then
	echo "Configurando Firewall...."
	iptables -t nat -A POSTROUTING -s $IPCONTAINER -j SNAT --to-source $IPSAMBA
	iptables -t nat -A PREROUTING -d $IPSAMBA -j DNAT --to-destination $IPCONTAINER
	else
	echo -e "Firewall já configurado"
fi

topsamba=$(docker ps | grep topsamba)

if [ -z "$topsamba" ]; then
	docker run \
	    -d \
	    --restart unless-stopped \
	    --name=topsamba \
	    --privileged \
	    --net nettopinfo \
	    --ip $IPCONTAINER \
	    --dns=127.0.0.1 \
	    --dns-search=$DOMAIN \
	    -e SAMBA_DC_REALM=$REALM \
	    -e SAMBA_DC_DOMAIN=$DOMAIN \
	    -e SAMBA_DC_ADMIN_PASSWD='T0p123#$' \
	    -e SAMBA_DC_DNS_BACKEND='BIND9_DLZ' \
	    -e IPSAMBA=$IPSAMBA \
	     "topinfo/samba:latest"
else
	echo -e "Tudo certo!\n"
fi
