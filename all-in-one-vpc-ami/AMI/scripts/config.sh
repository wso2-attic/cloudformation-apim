#!/bin/bash

# Exit on fail
set -e

sleep 30

export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

export DEBIAN_FRONTEND=noninteractive

echo "Installing packages..."
apt-get update
apt-get install -y unzip cron-apt nfs-common python python-pip
pip install --upgrade --user awscli
mkdir -p ~/.aws
cat > ~/.aws/credentials << EOF
[default]
aws_access_key_id = SED_AWS_KEY
aws_secret_access_key = SED_AWS_SECRET
EOF

cat > /usr/bin/wso2-wait-block.sh << EOF
#!/bin/bash
echo "Waiting WSO2 AM to launch on 9443..."
while ! nc -z 0.0.0.0 9443; do
  sleep 1
done

echo "WSO2AM launched"
EOF

chmod +x /usr/bin/wso2-wait-block.sh

echo "Mounting block device..."
mkfs.ext4 /dev/xvdf
cp /etc/fstab /etc/fstab.orig
mv /tmp/fstab /etc/fstab
mount -a

echo "Installing Java..."
wget --no-check-certificate --no-cookies --header "Cookie: oraclelicense=accept-securebackup-cookie" http://download.oracle.com/otn-pub/java/jdk/8u112-b15/jdk-8u112-linux-x64.tar.gz -P /tmp
tar zxvf /tmp/jdk-8u112-linux-x64.tar.gz -C /opt
ln -s /opt/jdk1.8.0_112/ /opt/java

# JDK Hardening
sed -i 's/#networkaddress.cache.ttl=-1/networkaddress.cache.ttl=30/' /opt/java/jre/lib/security/java.security
# Install java cryptographic extentions (JCE)
mv /opt/java/jre/lib/security/local_policy.jar{,.orig}
mv /opt/java/jre/lib/security/US_export_policy.jar{,.orig}

wget --no-check-certificate --no-cookies --header "Cookie: oraclelicense=accept-securebackup-cookie" http://download.oracle.com/otn-pub/java/jce/7/UnlimitedJCEPolicyJDK7.zip
unzip UnlimitedJCEPolicyJDK7.zip
mv UnlimitedJCEPolicy/*.jar /opt/java/jre/lib/security/
rm -rf /opt/jdk-7u80-linux-x64.tar.gz /opt/UnlimitedJCEPolicyJDK7.zip /opt/UnlimitedJCEPolicy

echo "Installing WSO2 API Manager 2.1.0..."
wget --user-agent="testuser" --referer="http://connect.wso2.com/wso2/getform/reg/new_product_download" http://product-dist.wso2.com/products/api-manager/2.1.0/wso2am-2.1.0.zip -P /tmp
unzip /tmp/wso2am-2.1.0.zip -d /opt

# Add MySQL Java Connector
wget https://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-5.1.41.zip -P /tmp
unzip /tmp/mysql-connector-java-5.1.41.zip -d /tmp
cp /tmp/mysql-connector-java-5.1.41/mysql-connector-java-5.1.41-bin.jar /opt/wso2am-2.1.0/repository/components/lib/

# Copy Templates
cp /tmp/wso2-templates/carbon.xml /opt/wso2am-2.1.0/repository/conf/carbon.xml
cp /tmp/wso2-templates/registry.xml /opt/wso2am-2.1.0/repository/conf/registry.xml
cp /tmp/wso2-templates/api-manager.xml /opt/wso2am-2.1.0/repository/conf/api-manager.xml
cp /tmp/wso2-templates/user-mgt.xml /opt/wso2am-2.1.0/repository/conf/user-mgt.xml
cp /tmp/wso2-templates/axis2.xml /opt/wso2am-2.1.0/repository/conf/axis2/axis2.xml
cp /tmp/wso2-templates/master-datasources.xml /opt/wso2am-2.1.0/repository/conf/datasources/master-datasources.xml

echo "Performing AMI hardening tasks..."
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
