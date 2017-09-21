#!/bin/bash -eux
# Based off the great "Preparing Linux Template VMs"
# (http://lonesysadmin.net/2013/03/26/preparing-linux-template-vms/) article
# by Bob Plankers, thanks Bob!

CLEANUP_PAUSE=${CLEANUP_PAUSE:-0}
echo "==> Pausing for ${CLEANUP_PAUSE} seconds..."
sleep ${CLEANUP_PAUSE}

#echo "==> erasing unused packages to free up space"
#/usr/bin/yum -y erase gtk2 hicolor-icon-theme avahi freetype bitstream-vera-fonts

echo "==> Cleaning up yum cache"
/usr/bin/yum clean all

echo "==> Force logs to rotate"
/usr/sbin/logrotate -f /etc/logrotate.conf
/bin/rm -f /var/log/*-???????? /var/log/*.gz

echo "==> Clear audit log and wtmp"
/bin/cat /dev/null > /var/log/audit/audit.log
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

echo "==> yum -y clean all"
yum -y clean all

echo "==> Zero out the free space to save space in the final image"
dd if=/dev/zero of=/EMPTY bs=1M
rm -rf /EMPTY

# Make sure we wait until all the data is written to disk, otherwise
# Packer might quit too early before the large files are deleted
sync
