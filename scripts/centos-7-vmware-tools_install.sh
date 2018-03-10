#!/bin/bash

echo "upgrading ca-certificates"
yum upgrade ca-certificates -y

sudo yum install perl fuse-libs net-tools make gcc -y
cd /tmp

# Hard coding the version of VMtools since the answer file is specific to this version
tar xfz VMwareTools-*.tar.gz
cd /tmp/vmware-tools-distrib
ls -la

# http://www.virtuallyghetto.com/2015/06/automating-silent-installation-of-vmware-tools-on-linux-wautomatic-kernel-modules.html
# If you wish to change which Kernel modules get installed
# The last four entries (no,no,no,no) map to the following:
#   VMware Host-Guest Filesystem
#   vmblock enables dragging or copying files
#   VMware automatic kernel modules
#   Guest Authentication
# and you can also change the other params as well
# This answer file is based off of VMwareTools-10.1.0-4449150.tar.gz responses
echo "upgrading ca-certificates"
yum upgrade ca-certificates -y

sudo cat > /tmp/answer << __ANSWER__
yes
/usr/bin
/etc/rc.d
/etc/rc.d/init.d
/usr/sbin
/usr/lib/vmware-tools
yes
/usr/lib
/var/lib
/usr/share/doc/vmware-tools
yes
yes
no
no
no
no
__ANSWER__

sudo /tmp/vmware-tools-distrib/vmware-install.pl < /tmp/answer

cd /tmp
rm -rf vmware-tools-distrib
rm -f VMwareTools*.tar.gz

sudo yum remove make gcc kernel-headers -y
