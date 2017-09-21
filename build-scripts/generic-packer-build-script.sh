#!/bin/bash

source /root/.packer-remote-creds

echo "deleting any existing folder named /root/packer-centos7-esxi/$PACKER_VM_NAME"
rm -rf /root/packer-centos7-esxi/${PACKER_VM_NAME}

echo "starting packer build of $PACKER_VM_NAME"
packer build -var-file=/root/.packer-remote-info.json /root/packer-centos7-esxi/templates/$PACKER_VM_NAME-$PACKER_VM_VERSION.json

#echo "registering ${PACKER_VM_NAME} virtual machine on ${PACKER_ESXI_HOST}"
#/usr/bin/sshpass -p ${PACKER_ESXI_PASSWORD} ssh ${PACKER_ESXI_USERNAME}@${PACKER_ESXI_HOST} "vim-cmd solo/registervm /vmfs/volumes/${PACKER_ESXI_DATASTORE}/output-${PACKER_VM_NAME}/*.vmx"

#echo "creating empty_dir folders at ${PACKER_EXPORT_PATH}/ovf/empty_dir/ & ${PACKER_EXPORT_PATH}/vmx/empty_dir/"
#mkdir -p ${PACKER_EXPORT_PATH}/ovf/empty_dir/
#mkdir -p ${PACKER_EXPORT_PATH}/vmx/empty_dir/

#echo "deleting the following folders if they exist: ${PACKER_EXPORT_PATH}/ovf/${PACKER_VM_NAME} & ${PACKER_EXPORT_PATH}/vmx/${PACKER_VM_NAME}"
#rm -rf ${PACKER_EXPORT_PATH}/vmx/${PACKER_VM_NAME}

#echo "output of /vmfs/volumes/${PACKER_ESXI_DATASTORE}/output-${PACKER_VM_NAME}/*.vmxf:"
#/usr/bin/sshpass -p ${PACKER_ESXI_PASSWORD} ssh ${PACKER_ESXI_USERNAME}@${PACKER_ESXI_HOST} "cat /vmfs/volumes/${PACKER_ESXI_DATASTORE}/output-${PACKER_VM_NAME}/*.vmxf"

#ovftool vi://root:${PACKER_REMOTE_PASSWORD}@${PACKER_REMOTE_HOST}/${PACKER_VM_NAME} ${PACKER_EXPORT_PATH}/ovf/

echo "creating metadata.json and Vagrantfile files in ovf virtual machine directory"
#echo '{"provider":"vmware_ovf"}' >> ${PACKER_EXPORT_PATH}/ovf/${PACKER_VM_NAME}/metadata.json
#touch ${PACKER_EXPORT_PATH}/ovf/${PACKER_VM_NAME}/Vagrantfile
echo '{"provider":"vmware_ovf"}' >> ${PACKER_VM_NAME}/${PACKER_VM_NAME}/metadata.json
touch ${PACKER_VM_NAME}/${PACKER_VM_NAME}/Vagrantfile

#cd ${PACKER_EXPORT_PATH}/ovf/empty_dir/
#cd ${PACKER_EXPORT_PATH}/ovf/${PACKER_VM_NAME}/
cd ${PACKER_VM_NAME}/${PACKER_VM_NAME}/

echo "compressing ovf virtual machine files to ${PACKER_EXPORT_PATH}/${PACKER_VM_NAME}-vmware_ovf-${PACKER_VM_VERSION}.box" 
tar cvzf ${PACKER_EXPORT_PATH}/$PACKER_VM_NAME-vmware_ovf-${PACKER_VM_VERSION}.box ./*

#echo "cleaning up ${PACKER_EXPORT_PATH} directories"
#rm -rf ${PACKER_EXPORT_PATH}/ovf/$PACKER_VM_NAME

#echo "deleting $PACKER_VM_NAME from $PACKER_ESXI_HOST"
#/usr/bin/sshpass -p ${PACKER_ESXI_PASSWORD} ssh root@${PACKER_ESXI_HOST}  "vim-cmd vmsvc/getallvms | grep ${PACKER_VM_NAME} | cut -d ' ' -f 1 | xargs vim-cmd vmsvc/destroy"

echo "packer build of $PACKER_VM_NAME has been  completed"

echo "ensuring atlas vagrant .box named $ATLASUSERNAME\$PACKER_VM_NAME has been created"
curl https://vagrantcloud.com/api/v1/boxes \
        -X POST \
        -d access_token=$ACCESSTOKEN \
        -d box[username]=$ATLASUSERNAME \
        -d box[name]=$PACKER_VM_NAME \
        -d box[is_private]=false \

echo "ensuring atlas vagrant .box named $ATLASUSERNAME\$PACKER_VM_NAME has version $PACKER_VM_VERSION created"
curl https://vagrantcloud.com/api/v1/box/$ATLASUSERNAME/$PACKER_VM_NAME/versions \
        -X POST \
        -d version[version]=$PACKER_VM_VERSION \
        -d version[description]='initial release' \
        -d access_token=$ACCESSTOKEN

echo "ensuring atlas vagrant .box named $ATLASUSERNAME\$PACKER_VM_NAME has vmware_ovf provider created"
curl https://vagrantcloud.com/api/v1/box/$ATLASUSERNAME/$PACKER_VM_NAME/version/$PACKER_VM_VERSION/providers \
-X POST \
-d provider[name]='vmware_ovf' \
-d access_token=$ACCESSTOKEN

echo "uploading $ATLASUSERNAME\\$PACKER_VM_NAME vmware_desktop packer .box file"
ATLASPATH=$(curl -L "https://vagrantcloud.com/api/v1/box/$ATLASUSERNAME/$PACKER_VM_NAME/version/$PACKER_VM_VERSION/provider/vmware_ovf/upload?access_token=$ACCESSTOKEN" |cut -d "," -f1 | cut -d'"' -f4)
echo $ATLASPATH

curl -X PUT --upload-file "$PACKER_EXPORT_PATH/$PACKER_VM_NAME-vmware_ovf-$PACKER_VM_VERSION.box" $ATLASPATH

echo "releasing version $PACKER_VM_VERSION of $ATLASUSERNAME\$PACKER_VM_NAME vmware_ovf packer .box file"
curl https://vagrantcloud.com/api/v1/box/$ATLASUSERNAME/$PACKER_VM_NAME/version/$PACKER_VM_VERSION/release -X PUT -d access_token="$ACCESSTOKEN"

