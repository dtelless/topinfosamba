#!/bin/bash
# Copyright 2017-TODAY LasLabs Inc.
# License Apache 2.0 (https://www.apache.org/licenses/LICENSE-2.0.html).

set -e

COMMAND=bash

# Add $COMMAND if needed
#if [ "${1:0:1}" = '-' ]; then
#	set -- $COMMAND "$@"
#fi
/etc/init.d/bind9 start
# Configure the AD DC

if [ ! -f /samba/etc/smb.conf ]; then
    echo "${SAMBA_DC_DOMAIN} - Begin Domain Provisioning"
    samba-tool domain provision --domain="${SAMBA_DC_DOMAIN}" \
        --adminpass="${SAMBA_DC_ADMIN_PASSWD}" \
        --server-role=dc \
        --realm="${SAMBA_DC_REALM}" \
        --dns-backend="${SAMBA_DC_DNS_BACKEND}"
    echo "${SAMBA_DC_DOMAIN} - Domain Provisioned Successfully"

	if [ -f /var/lib/samba/private/named.conf ] ; then
		cp /var/lib/samba/private/krb5.conf /etc/krb5.conf
		samba_dnsupdate --current-ip="${IPSAMBA}" --verbose
		touch /var/log/bind.log
		chown bind /var/log/bind.log
		mv /etc/bind/namedsamba.conf /etc/bind/named.conf
		/etc/init.d/bind9 restart
	fi
fi

if [ "$1" = 'samba' ]; then
    /etc/init.d/bind9 start
    exec /usr/sbin/samba -i
fi

# Assume that user wants to run their own process,
# for example a `bash` shell to explore this image
# exec "echo hello"
