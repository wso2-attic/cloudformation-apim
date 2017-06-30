#!/bin/bash

# Attach ENI and associate EIP
instance_id=$(curl http://169.254.169.254/latest/meta-data/instance-id)
aws ec2 attach-network-interface --network-interface-id CF_ENI_ID --instance-id $instance_id --device-index 1
aws ec2 associate-address --allocation-id CF_ALLOC_ID --network-interface-id CF_ENI_ID

# Setup device
ifup eth1

# Setup routing
echo "200 out" >>/etc/iproute2/rt_tables

ip route add default via CF_DEFAULT_GATEWAY dev eth1 table out

ip rule add from CF_ENI_PRIVATE_IP/32 table out
ip rule add to CF_ENI_PRIVATE_IP/32 table out
ip route flush cache
