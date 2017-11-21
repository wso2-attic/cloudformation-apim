#!/usr/bin/env python3

import boto3
import sys


def get_private_ip(
        aws_region, aws_access_key_id, aws_access_key_secret, instance_name):
    #   initialize the boto3 client
    client = boto3.client(
        'autoscaling', region_name=aws_region,
        aws_access_key_id=aws_access_key_id,
        aws_secret_access_key=aws_access_key_secret)
    #   get information of existing auto scaling groups
    response = client.describe_auto_scaling_groups()

    #   capture the auto scaling group based on tag name
    instance_id = None
    for group in response['AutoScalingGroups']:
        tags = group['Tags']
        for tag in tags:
            if tag['Key'] == 'Name' and tag['Value'] == instance_name:
                instances = group['Instances']
                if len(instances) > 0:
                    instance_id = instances[0]['InstanceId']

    #   get EC2 instance information
    ec2_client = boto3.client(
        'ec2', region_name=aws_region, aws_access_key_id=aws_access_key_id,
        aws_secret_access_key=aws_access_key_secret)
    ec2_response = ec2_client.describe_instances(InstanceIds=[instance_id])

    #   capture private IP address of the EC2 instance
    if len(ec2_response['Reservations']) > 0:
        if len(ec2_response['Reservations'][0]['Instances']) > 0:
            return (ec2_response['Reservations'][0]
                    ['Instances'][0]['PrivateIpAddress'])
        else:
            return None
    else:
        return None


if __name__ == '__main__':
    region = sys.argv[1]
    access_key_id = sys.argv[2]
    access_key_secret = sys.argv[3]
    instance_name = sys.argv[4]
    print(
        get_private_ip(
            region, access_key_id, access_key_secret, instance_name))
