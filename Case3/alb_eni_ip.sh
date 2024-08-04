#!/bin/bash

# Function to get ENI IDs for a given ALB
get_alb_eni_ids() {
    local alb_name=$1
    local eni_ids=$(aws elbv2 describe-load-balancers --names $alb_name --query "LoadBalancers[0].AvailabilityZones[*].NetworkInterfaceId" --output text)
    echo $eni_ids
}

# Function to get IP addresses for a given ENI ID
get_eni_ips() {
    local eni_id=$1
    local private_ip=$(aws ec2 describe-network-interfaces --network-interface-ids $eni_id --query "NetworkInterfaces[0].PrivateIpAddress" --output text)
    local public_ip=$(aws ec2 describe-network-interfaces --network-interface-ids $eni_id --query "NetworkInterfaces[0].Association.PublicIp" --output text)
    echo "ENI ID: $eni_id, Private IP: $private_ip, Public IP: $public_ip"
}

# ALB Names
alb_names=("VPC01-alb" "VPC02-alb")

# Iterate over each ALB name
for alb_name in "${alb_names[@]}"; do
    echo "ALB Name: $alb_name"
    eni_ids=$(get_alb_eni_ids $alb_name)
    if [[ -n "$eni_ids" ]]; then
        for eni_id in $eni_ids; do
            ips=$(get_eni_ips $eni_id)
            echo $ips
        done
    else
        echo "No ENIs found for ALB $alb_name or you don't have permissions to view them."
    fi
    echo "-----------------------"
done