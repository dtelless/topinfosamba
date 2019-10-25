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
	cat > /etc/samba/smb.conf <<EOF
[global]
        netbios name = ${NOMESRV}
        realm = ${SAMBA_DC_REALM}
        server role = active directory domain controller
        server services = s3fs, rpc, nbt, wrepl, ldap, cldap, kdc, drepl, winbindd, ntp_signd, kcc, dnsupdate
        workgroup = ${SAMBA_DC_DOMAIN}
        host msdfs = yes

        idmap_ldb:use rfc2307 = yes
        idmap config * : backend = tdb
        idmap config * : range = 30000-31000
        winbind nss info = rfc2307
        winbind use default domain = yes
        winbind enum users = yes
        winbind enum groups = yes
        vfs objects = acl_xattr
        map acl inherit = Yes
        store dos attributes = Yes

[netlogon]
        path = /var/lib/samba/sysvol/${SAMBA_DC_REALM}/scripts
        read only = No

[sysvol]
        path = /var/lib/samba/sysvol
        read only = No

[dfs]
        comment = DFS Root Share
        path = /export/dfsroot
        browsable = yes
        msdfs root = yes
        read only = no

[departamenos]
        path = /export/samba/departamentos
        public = yes
        writable = yes
        browseable = yes
EOF


	if [ -f /var/lib/samba/private/named.conf ] ; then
		cp /var/lib/samba/private/krb5.conf /etc/krb5.conf
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
