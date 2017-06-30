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
apt-get install -y unzip zip cron-apt nfs-common puppet facter mysql-client python python-pip
pip install --upgrade --user awscli

echo "Mounting block device..."
mkfs.ext4 /dev/xvdf
cp /etc/fstab /etc/fstab.orig
mv /tmp/fstab /etc/fstab
mount -a

echo "Setting up Puppet..."
cp -r /tmp/puppet/* /etc/puppet/

puppet module install puppetlabs/stdlib
puppet module install 7terminals-java

echo "Downloading packs..."
# JDK
wget --tries=3 -q --no-check-certificate --no-cookies --header "Cookie: oraclelicense=accept-securebackup-cookie" http://download.oracle.com/otn-pub/java/jdk/8u131-b11/d54c1d3a095b4ff2b6607d096fa80163/jdk-8u131-linux-x64.tar.gz -P /etc/puppet/files/packs

# MySQL Connector
wget --tries=3 -q https://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-5.1.41.zip -P /tmp
unzip -q /tmp/mysql-connector-java-5.1.41.zip -d /tmp

# IP Allocation script
mv /tmp/allocate_ips.sh /usr/local/bin/
mv /tmp/eth1.cfg /etc/network/interfaces.d/ 
chmod +x /usr/local/bin/allocate_ips.sh

if [ "$CF_PRODUCT" == "APIM" ]; then
  # Download pack
  wget --tries=3 -q --user-agent="testuser" --referer="http://connect.wso2.com/wso2/getform/reg/new_product_download" http://product-dist.wso2.com/products/api-manager/2.1.0/wso2am-2.1.0.zip -P /etc/puppet/modules/wso2am_runtime/files

  # Copy MySQL Connector Lib
  mkdir -p /etc/puppet/modules/wso2am_runtime/files/configs/repository/components/lib
  cp /tmp/mysql-connector-java-5.1.41/mysql-connector-java-5.1.41-bin.jar /etc/puppet/modules/wso2am_runtime/files/configs/repository/components/lib

  # Copy DB provisioning script
  mv /tmp/provision_db_apim.sh /usr/local/bin/
  chmod +x /usr/local/bin/provision_db_apim.sh
fi

if [ "$CF_PRODUCT" == "APIM-ANALYTICS" ]; then
  # Download pack
  wget --tries=3 -q --user-agent="testuser" --referer="http://connect.wso2.com/wso2/getform/reg/new_product_download" http://product-dist.wso2.com/products/api-manager/2.1.0/wso2am-analytics-2.1.0.zip -P /etc/puppet/modules/wso2am_analytics/files

  # Copy MySQL Connector Lib
  mkdir -p /etc/puppet/modules/wso2am_analytics/files/configs/repository/components/lib
  cp /tmp/mysql-connector-java-5.1.41/mysql-connector-java-5.1.41-bin.jar /etc/puppet/modules/wso2am_analytics/files/configs/repository/components/lib

  # Copy DB provisioning script
  mv /tmp/provision_db_analytics.sh /usr/local/bin/
  chmod +x /usr/local/bin/provision_db_analytics.sh
fi

# Setup JDK
tar zxf /etc/puppet/files/packs/jdk-8u131-linux-x64.tar.gz -C /opt
ln -s /opt/jdk1.8.0_131/ /opt/java

cp /tmp/set_java_home.sh /etc/profile.d/set_java_home.sh

# Copy deployment management lock binary
mv /tmp/sync_lock-linux-x64 /usr/local/bin/sync_lock
chmod +x /usr/local/bin/sync_lock
mv /tmp/acquire_lock.sh /usr/local/bin/acquire_lock.sh
chmod +x /usr/local/bin/acquire_lock.sh

# cp /etc/puppet/files/packs/jdk-8u131-linux-x64.tar.gz /etc/puppet/modules/wso2base/files
# export FACTER_product_name=wso2am_analytics
# export FACTER_product_version=2.1.0
# export FACTER_product_profile=default
# export FACTER_vm_type=openstack
# export FACTER_environment=dev
# export FACTER_platform=default
# export FACTER_use_hieradata=true
# export FACTER_pattern=pattern-1
#
# puppet apply --debug -e "include wso2am_analytics" --modulepath=/etc/puppet/modules --hiera_config=/etc/puppet/hiera.yaml

echo "Performing AMI Hardening Tasks..."
# JDK Hardening: Name lookup cache
sed -i 's/#networkaddress.cache.ttl=-1/networkaddress.cache.ttl=30/' /opt/java/jre/lib/security/java.security

# JDK Hardening: Install java cryptographic extentions (JCE)
mv /opt/java/jre/lib/security/local_policy.jar{,.orig}
mv /opt/java/jre/lib/security/US_export_policy.jar{,.orig}
wget --tries=3 -q --no-check-certificate --no-cookies --header "Cookie: oraclelicense=accept-securebackup-cookie" http://download.oracle.com/otn-pub/java/jce/7/UnlimitedJCEPolicyJDK7.zip
unzip -q UnlimitedJCEPolicyJDK7.zip
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
