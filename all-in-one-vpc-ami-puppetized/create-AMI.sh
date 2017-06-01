#!/bin/bash

# Check if Packer exists
command -v packer >/dev/null 2>&1 || { echo >&2 "Packer was not found. Please install Packer first."; exit 1; }

pushd AMI > /dev/null 2>&1
packer validate am-default.json
echo

if [ $? != 0 ]; then
  exit 1;
fi

aws_access_key=${AWS_ACCESS_KEY_ID? "Environment variable AWS_ACCESS_KEY_ID is not set"}
aws_secret_access_key=${AWS_SECRET_ACCESS_KEY? "Environment variable AWS_SECRET_ACCESS_KEY is not set"}

echo "Starting packer build with docker..."
docker run -e AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID \
           -e AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY \
           -i -t -v $(pwd):/opt/ -w /opt/ hashicorp/packer:light build /opt/am-default.json

popd > /dev/null 2>&1
echo "DONE!"
