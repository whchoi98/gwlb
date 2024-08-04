#!/bin/bash

# Query the DNS Name for ALB "VPC01-alb"
VPC01ALB_FQDN=$(aws elbv2 describe-load-balancers --names VPC01-alb --query "LoadBalancers[0].DNSName" --output text)

# Query the DNS Name for ALB "VPC02-alb"
VPC02ALB_FQDN=$(aws elbv2 describe-load-balancers --names VPC02-alb --query "LoadBalancers[0].DNSName" --output text)

# Check if the commands were successful
if [[ -z "$VPC01ALB_FQDN" || -z "$VPC02ALB_FQDN" ]]; then
    echo "Failed to retrieve DNS names for the ALBs. Please check if the ALBs exist and you have the necessary permissions."
    exit 1
fi

# Append the variables to the .bash_profile
echo "export VPC01ALB_FQDN=$VPC01ALB_FQDN" >> ~/.bash_profile
echo "export VPC02ALB_FQDN=$VPC02ALB_FQDN" >> ~/.bash_profile

# Source the .bash_profile to apply the changes
source ~/.bash_profile

# Print the results
echo "VPC01ALB_FQDN is set to $VPC01ALB_FQDN"
echo "VPC02ALB_FQDN is set to $VPC02ALB_FQDN"