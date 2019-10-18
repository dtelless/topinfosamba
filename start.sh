#!/bin/bash
IPLOCAL=""
IPSAMBA="192.168.171.212"
IPCONTAINER="10.0.5.10"
REDEDOCKER="10.0.5.0/24"


function installdocker {
sudo apt update
sudo apt install apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable"
sudo apt update
sudo apt install docker-ce
apt-cache policy docker-ce
sudo systemctl status docker
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
fi

imagem=$(docker image ls | grep topinfo)

if [ ! -z "$imagem" ]; then
	echo -e "Criando imagem para o Container\n"
	createimage
fi

rede=$(docker network ls | grep nettopinfo)

if [ ! -z "$rede" ]; then
	echo "Criando rede virtual\n"
        createvirtualnetwork
fi

firewallDNAT=$(iptables -L -t nat | grep DNAT | grep $IPCONTAINER)
firewallSNAT=$(iptables -L -t nat | grep SNAT | grep $IPCONTAINER)

if [-z $firewallDNAT && -z $firewallSNAT]; then
	echo "Configurando Firewall...."
	iptables -t nat -A POSTROUTING -s $IPCONTAINER -j SNAT --to-source $IPSAMBA
	iptables -t nat -A PREROUTING -d $IPSAMBA -j DNAT --to-destination $IPCONTAINER
	;else;
	print -e "Firewall já configurado"
fi

docker run -d --restart unless-stopped \
    --privileged \
    --net nettopinfo \
    --ip $IPCONTAINER \
    -e SAMBA_DC_REALM='brservicer.local' \
    -e SAMBA_DC_DOMAIN='brservicer' \
    -e SAMBA_DC_ADMIN_PASSWD='T0p123#$' \
    -e SAMBA_DC_DNS_BACKEND='BIND9_DLZ' \
     "topinfo/samba:latest"
