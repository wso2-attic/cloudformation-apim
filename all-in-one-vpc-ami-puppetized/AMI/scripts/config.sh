#!/bin/bash

# Exit on fail
set -e

sleep 30

export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

export DEBIAN_FRONTEND=noninteractive

echo "Installing packages..."
wget https://apt.puppetlabs.com/puppetlabs-release-trusty.deb
dpkg -i puppetlabs-release-trusty.deb
apt-get update
apt-get install -y unzip cron-apt nfs-common puppet facter

chmod +x /tmp/wait-for-9443.sh

echo "Mounting block device..."
mkfs.ext4 /dev/xvdf
cp /etc/fstab /etc/fstab.orig
mv /tmp/fstab /etc/fstab
mount -a

echo "Setting up Puppet..."
cp -r /tmp/puppet/* /etc/puppet/
mkdir -p /etc/facter/facts.d
mv /tmp/wso2-facts.txt /etc/facter/facts.d/

puppet module install puppetlabs/stdlib
puppet module install 7terminals-java

echo "Downloading packs..."
wget --tries=3 --no-check-certificate --no-cookies --header "Cookie: oraclelicense=accept-securebackup-cookie" http://download.oracle.com/otn-pub/java/jdk/8u131-b11/d54c1d3a095b4ff2b6607d096fa80163/jdk-8u131-linux-x64.tar.gz -P /etc/puppet/files/packs
wget --tries=3 --user-agent="testuser" --referer="http://connect.wso2.com/wso2/getform/reg/new_product_download" http://product-dist.wso2.com/products/api-manager/2.1.0/wso2am-2.1.0.zip -P /etc/puppet/modules/wso2am_runtime/files

wget --tries=3 https://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-5.1.41.zip -P /tmp
unzip /tmp/mysql-connector-java-5.1.41.zip -d /tmp
mkdir -p /etc/puppet/modules/wso2am_runtime/files/configs/repository/components/lib
cp /tmp/mysql-connector-java-5.1.41/mysql-connector-java-5.1.41-bin.jar /etc/puppet/modules/wso2am_runtime/files/configs/repository/components/lib

# export FACTER_product_name=wso2am_runtime
# export FACTER_product_version=2.1.0
# export FACTER_product_profile=default
# export FACTER_vm_type=openstack
# export FACTER_environment=dev
# export FACTER_platform=default
# export FACTER_use_hieradata=true
# export FACTER_pattern=pattern-1
#
# puppet apply --debug -e "include wso2am_runtime" --modulepath=/etc/puppet/modules --hiera_config=/etc/puppet/hiera.yaml

echo "Performing AMI Hardening Tasks..."
# JDK Hardening: Name lookup cache
sed -i 's/#networkaddress.cache.ttl=-1/networkaddress.cache.ttl=30/' /opt/java/jre/lib/security/java.security

# JDK Hardening: Install java cryptographic extentions (JCE)
mv /opt/java/jre/lib/security/local_policy.jar{,.orig}
mv /opt/java/jre/lib/security/US_export_policy.jar{,.orig}
wget --tries=3 --no-check-certificate --no-cookies --header "Cookie: oraclelicense=accept-securebackup-cookie" http://download.oracle.com/otn-pub/java/jce/7/UnlimitedJCEPolicyJDK7.zip
unzip UnlimitedJCEPolicyJDK7.zip
mv UnlimitedJCEPolicy/*.jar /opt/java/jre/lib/security/
rm -rf /opt/jdk-7u80-linux-x64.tar.gz /opt/UnlimitedJCEPolicyJDK7.zip /opt/UnlimitedJCEPolicy

# OS Hardening: SSH
sed -i 's/PermitRootLogin yes/PermitRootLogin no/g' /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config

# OS Hardening: Limits
cp /etc/security/limits.conf /etc/security/limits.conf.orig
mv /tmp/limits.conf /etc/security/limits.conf

# OS Hardening: Sysctl
mv /etc/sysctl.conf /etc/sysctl.conf.orig
mv /tmp/sysctl.conf /etc/sysctl.conf

# Cleaning APT
mv /etc/apt/sources.list /etc/apt/sources.orig
mv /tmp/security.sources.list /etc/apt/sources.list.d/security.sources.list
mv /tmp/5-install /etc/cron-apt/action.d/5-install
apt-get update

# OS Hardening: History
echo 'export HISTTIMEFORMAT="%F %T "' >> /etc/profile.d/history.sh
# Clear history
cat /dev/null > ~/.bash_history && history -c
