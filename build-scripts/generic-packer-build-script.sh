#!/bin/bash

source /root/.packer-remote-creds

echo "deleting any existing folder named /root/packer-centos7-esxi/$PACKER_VM_NAME"
rm -rf /root/packer-centos7-esxi/output-${PACKER_VM_NAME}

echo "starting packer build of $PACKER_VM_NAME"
packer build -var-file=/root/.packer-remote-info.json /root/packer-centos7-esxi/templates/$PACKER_VM_NAME-$PACKER_VM_VERSION.json


echo "creating metadata.json and Vagrantfile files in ovf virtual machine directory"
echo '{"provider":"vmware_ovf"}' >> output-${PACKER_VM_NAME}/${PACKER_VM_NAME}/metadata.json
touch output-${PACKER_VM_NAME}/${PACKER_VM_NAME}/Vagrantfile

cd output-${PACKER_VM_NAME}/${PACKER_VM_NAME}/

echo "compressing ovf virtual machine files to ${PACKER_EXPORT_PATH}/${PACKER_VM_NAME}-vmware_ovf-${PACKER_VM_VERSION}.box" 
tar cvzf ${PACKER_EXPORT_PATH}/$PACKER_VM_NAME-vmware_ovf-${PACKER_VM_VERSION}.box ./*

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

