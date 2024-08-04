#!/bin/bash

# Function to get ENI IDs for a given ALB
get_alb_eni_ids() {
    local alb_name=$1
    local alb_arn=$(aws elbv2 describe-load-balancers --names $alb_name --query "LoadBalancers[0].LoadBalancerArn" --output text)
    local eni_ids=$(aws elbv2 describe-load-balancer-attributes --load-balancer-arn $alb_arn --query "Attributes[?Key=='subnet-ids'].Value[]" --output text)
    echo $eni_ids
}

# Function to get ENIs in a subnet
get_subnet_eni_ids() {
    local subnet_id=$1
    local eni_ids=$(aws ec2 describe-network-interfaces --filters "Name=subnet-id,Values=$subnet_id" "Name=description,Values=*elasticloadbalancing*" --query "NetworkInterfaces[*].NetworkInterfaceId" --output text)
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
    subnet_ids=$(get_alb_eni_ids $alb_name)
    if [[ -n "$subnet_ids" ]]; then
        for subnet_id in $subnet_ids; do
            eni_ids=$(get_subnet_eni_ids $subnet_id)
            if [[ -n "$eni_ids" ]]; then
                for eni_id in $eni_ids; do
                    ips=$(get_eni_ips $eni_id)
                    echo $ips
                done
            else
                echo "No ENIs found in subnet $subnet_id for ALB $alb_name."
            fi
        done
    else
        echo "No subnets found for ALB $alb_name or you don't have permissions to view them."
    fi
    echo "-----------------------"
done