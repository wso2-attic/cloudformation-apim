#!/bin/bash

packer_file="packer-conf.json"

# Check if Packer exists
command -v packer >/dev/null 2>&1 || { echo >&2 "Packer was not found. Please install Packer first."; exit 1; }

function showUsageAndExit(){
  echo "Invalid usage. Please specify the product to create an AMI."
  echo
  echo "Supported products:"
  echo "  APIM           - WSO2 API Manager"
  echo "  APIM-ANALYTICS - WSO2 API Manager Analytics"
  echo
  echo "Supported versions"
  echo "  2.1.0"
  echo
  echo "Usage: "
  echo "    bash create-AMI.sh -p APIM"
  echo "    bash create-AMI.sh -p APIM-ANALYTICS"
  echo
  exit 1
}

product=""
version="2.1.0" # Only 2.1.0 is supported as of now
while getopts :p: FLAG; do
  case $FLAG in
    p)
      product=$OPTARG
      ;;
    \?)
      showUsageAndExit
      ;;
  esac
done

if [ -z $product ]; then
  showUsageAndExit
fi

if [ "$product" != "APIM" ] && [ "$product" != "APIM-ANALYTICS" ]; then
  showUsageAndExit
fi

if [[ "$OSTYPE" == *"darwin"* ]]; then
  aws_access_key=${AWS_ACCESS_KEY_ID? "Environment variable AWS_ACCESS_KEY_ID is not set"}
  aws_secret_access_key=${AWS_SECRET_ACCESS_KEY? "Environment variable AWS_SECRET_ACCESS_KEY is not set"}

  echo "Starting packer validation with docker..."
  docker run -e AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID \
             -e AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY \
             -i -t -v $(pwd):/opt/ -w /opt/ hashicorp/packer:light validate \
             /opt/$packer_file
else
  packer validate $packer_file
fi
echo

if [ $? != 0 ]; then
  exit 1;
fi

if [[ "$OSTYPE" == *"darwin"* ]]; then
  aws_access_key=${AWS_ACCESS_KEY_ID? "Environment variable AWS_ACCESS_KEY_ID is not set"}
  aws_secret_access_key=${AWS_SECRET_ACCESS_KEY? "Environment variable AWS_SECRET_ACCESS_KEY is not set"}

  echo "Starting packer build with docker..."
  docker run -e AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID \
             -e AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY \
             -i -t -v $(pwd):/opt/ -w /opt/ hashicorp/packer:light build \
             -var "product=${product}" \
             -var "version=${version}" \
             /opt/$packer_file
else
  aws_credentials=""
  if [ ! -e ~/.aws/credentials ]; then
    echo -n "AWS Access Key: "
    read -r access_key

    echo -n "AWS Access Secret: "
    read -s secret_key
    echo
    echo

    aws_credentials="-var \"aws_access_key=${access_key}\" -var \"aws_secret_key=${secret_key}\""
  fi
  packer build $aws_credentials -var "product=${product}" -var "version=${version}" $packer_file
fi

echo "DONE!"
