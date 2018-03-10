This repository provides a working template for using packer to build a CentOS 7 .box using the vmware-iso builder with ESXi and then storing the created .box file on vagrant cloud.

In order to use this repository you need the following:
* Install packer from [this link](https://www.packer.io/downloads.html)
* Install ovftool from [this link](https://my.vmware.com/web/vmware/details?productId=353&downloadGroup=OVFTOOL400)
* Download a copy of the CentOS 7 minimal .iso and put is into the iso/ directory. You can find more details about this by looking at the iso/info.txt file in this repository.
* Place a copy of the linux VMtool tar.gz in the iso/ directory. I used VMwareTools-10.1.7-5541682.tar.gz pulled from a ESXi 6.5 host for my testing.
* A ESXi 5.5 or 6.0 host with standard portgroups for building templates on. DVSwitch portgroups are not currently supported with packer. You should read the steps listed at [the Packer vmware-iso builder page](https://www.packer.io/docs/builders/vmware-iso.html#building-on-a-remote-vsphere-hypervisor) about using an ESXi host.
The two command that you run to enable on a ESXi 6.x host for packer use are:
```
# enable GuestIpHack to allow packer to determine the vm IP address before vmtools are installed
esxcli system settings advanced set -o /Net/GuestIPHack -i 1
# open inbound VNC connections on the firewall
esxcli network firewall ruleset set -e true -r gdbserver
```
* A DHCP server on the port group you are using to build templates. Packer uses SSH to interact with the template once the OS is installed, so the template needs to be assigned a IP address in order to use provisioners to configure it.
* A vagrant cloud account to upload your vmware_ovf .box file to.
* Create ~/.packer-remote-creds that includes the environmental variables for the specifics of your the ESXi host, used for building the template, and vagrant cloud, used for storing the .box template that is built. Here is an example file with the environmental variables referenced in the Packer template:
```
[root@packer ~]# cat ~/.packer-remote-creds 
export ROOT_PASSWD='vagrant'
export PACKER_ESXI_HOST='192.168.1.51'
export PACKER_ESXI_USERNAME='root'
export PACKER_ESXI_PASSWORD='password'
export PACKER_ESXI_DATASTORE='local-datastore'
export PACKER_ESXI_PORTGROUP='VM_Network'
export PACKER_EXPORT_PATH='/mnt/nfs/virtual_machines/packer_box_files/'
export ATLASUSERNAME='standorsett' # your vagrant cloud username
export ATLASACCESSTOKEN='[your_vagrant_cloud_access_token]'
[root@packer ~]# 
```

Once the file containing the environmental credentials variables is created you can kick off the build proccess by passing the PACKER_VM_NAME and PACKER_VM_VERSION into build-scripts/generic-packer-build-script.sh:
```
PACKER_VM_NAME=centos-7 PACKER_VM_VERSION='1707.01' build-scripts/generic-packer-build-script.sh
```
The build-scripts/generic-packer-build-script.sh will use the PACKER_VM_NAME and PACKER_VM_VERSION variables to select what packer template is run and also used when uploading the template to vagrant cloud:
```
packer build /root/packer-centos7-esxi/templates/$PACKER_VM_NAME-$PACKER_VM_VERSION.json
```

This template has been tested building on ESXi 6.5 using packer 1.0.4 running on CentOS 7.3.
The ESXi 6.5 server I used for building packer templates was a nested ESXi vm deployed using William Lam's ESXi 6.5 .ovf template documented [here](http://www.virtuallyghetto.com/2015/12/deploying-nested-esxi-is-even-easier-now-with-the-esxi-virtual-appliance.html).

The following vagrant cloud images have been built using this template:
* Centos 7.3-1707 - [Link](https://app.vagrantup.com/standorsett/boxes/centos-7/versions/1707.01)
* Centos 7.4-1708 - [Link](https://app.vagrantup.com/standorsett/boxes/centos-7/versions/1708.01)

