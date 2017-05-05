#!/bin/bash

# Check if Packer exists
command -v packer >/dev/null 2>&1 || { echo >&2 "Packer was not found. Please install Packer first."; exit 1; }

pushd AMI > /dev/null 2>&1
packer validate am-default.json
echo

if [ $? != 0 ]; then
  exit 1;
fi

echo -n "AWS Access Key: "
read -r access_key

echo -n "AWS Access Secret: "
read -s secret_key
echo
echo 

packer build -var "aws_access_key=${access_key}" -var "aws_secret_key=${secret_key}" am-default.json

popd > /dev/null 2>&1
echo "DONE!"
