#!/bin/bash -eux

systemctl enable vmtoolsd.service
systemctl start vmtoolsd.service

# modify docker to use docker volume group and extend docker-pool logical volume
systemctl stop docker
rm -rf /var/lib/docker/
sed -i'' -e 's/CONTAINER_THINPOOL=.*/VG=docker/' /etc/sysconfig/docker-storage-setup
systemctl start docker
lvextend -l +100%FREE /dev/docker/docker-pool

# Based off the great "Preparing Linux Template VMs"
# (http://lonesysadmin.net/2013/03/26/preparing-linux-template-vms/) article
# by Bob Plankers, thanks Bob!

CLEANUP_PAUSE=${CLEANUP_PAUSE:-0}
echo "==> Pausing for ${CLEANUP_PAUSE} seconds..."
sleep ${CLEANUP_PAUSE}

echo "==> Force logs to rotate"
/usr/sbin/logrotate -f /etc/logrotate.conf
/bin/rm -f /var/log/*-???????? /var/log/*.gz

echo "==> Clear wtmp"
/bin/cat /dev/null > /var/log/wtmp

echo "==> Cleaning up udev rules"
/bin/rm -f /etc/udev/rules.d/70*

echo "==> Remove the traces of the template MAC address and UUIDs"

sed -i'' -e '/UUID=/d' /etc/sysconfig/network-scripts/ifcfg-eth0
sed -i'' -e '/HWADDR=/d' /etc/sysconfig/network-scripts/ifcfg-eth0
sed -i'' -e '/DHCP_HOSTNAME=/d' /etc/sysconfig/network-scripts/ifcfg-eth0
sed -i'' -e 's/NM_CONTROLLED=.*/NM_CONTROLLED="no"/' /etc/sysconfig/network-scripts/ifcfg-eth0

echo "==> Cleaning up tmp"
/bin/rm -rf /tmp/*
/bin/rm -rf /var/tmp/*

echo "==> Remove the SSH host keys"
/bin/rm -f /etc/ssh/*key*

echo "==> Remove the root user’s shell history"
/bin/rm -f ~root/.bash_history
unset HISTFILE

echo "==> Zero out the free space to save space in the final image"
dd if=/dev/zero of=/root/EMPTY bs=1M
rm -rf /root/EMPTY

# Make sure we wait until all the data is written to disk, otherwise
# Packer might quit too early before the large files are deleted
sync
