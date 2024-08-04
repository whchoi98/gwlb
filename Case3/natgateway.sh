#!/bin/bash

# Function to get NAT Gateway ID by name
get_nat_gateway_id() {
    local name=$1
    local id=$(aws ec2 describe-nat-gateways --query "NatGateways[?Tags[?Key=='Name'&&Value=='$name']].NatGatewayId" --output text)
    echo $id
}

# Function to get Private and Public IPs of a NAT Gateway by ID
get_nat_gateway_ips() {
    local nat_gateway_id=$1
    local private_ip=$(aws ec2 describe-nat-gateways --nat-gateway-ids $nat_gateway_id --query "NatGateways[0].NatGatewayAddresses[0].PrivateIp" --output text)
    local public_ip=$(aws ec2 describe-nat-gateways --nat-gateway-ids $nat_gateway_id --query "NatGateways[0].NatGatewayAddresses[0].PublicIp" --output text)
    echo "Private IP: $private_ip, Public IP: $public_ip"
}

# NAT Gateway Names
nat_gateway_names=("VPC01-NATGW-A" "VPC01-NATGW-B" "VPC02-NATGW-A" "VPC02-NATGW-B")

# Iterate over each NAT Gateway name
for name in "${nat_gateway_names[@]}"; do
    echo "NAT Gateway Name: $name"
    nat_gateway_id=$(get_nat_gateway_id $name)
    if [[ -n "$nat_gateway_id" ]]; then
        echo "NAT Gateway ID: $nat_gateway_id"
        ips=$(get_nat_gateway_ips $nat_gateway_id)
        echo $ips
    else
        echo "NAT Gateway not found or you don't have permissions to view it."
    fi
    echo "-----------------------"
done