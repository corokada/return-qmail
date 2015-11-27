#!/bin/sh

#
# DKIM/DomainKeys Generate keys
#
# Author: corokada
#

if [ -z "$1" ]; then
        echo "usage:$0 [domain-name]"
        exit 0
fi

mkdir -p /usr/local/etc/domainkeys/$1

cd /etc/domainkeys/$1
/usr/local/bin/dknewkey default 1024 > default.pub
chmod 640 /etc/domainkeys/$1/default
chown root:qmail /etc/domainkeys/$1/default

echo "$1 DNS records adding sample"
cat /etc/domainkeys/$1/default.pub
echo -e "_adsp._domainkey\tIN\tTXT\t\"dkim=unknown\""
