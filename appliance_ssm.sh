#!/bin/bash
# command ./appliacne_ssm.sh

aws ec2 describe-instances --filters 'Name=tag:Name,Values=GWLBVPC-Appliance-10.254.11.101' 'Name=instance-state-name,Values=running' | jq -r '.Reservations[].Instances[].InstanceId'
aws ec2 describe-instances --filters 'Name=tag:Name,Values=GWLBVPC-Appliance-10.254.11.102' 'Name=instance-state-name,Values=running' | jq -r '.Reservations[].Instances[].InstanceId'
aws ec2 describe-instances --filters 'Name=tag:Name,Values=GWLBVPC-Appliance-10.254.12.101' 'Name=instance-state-name,Values=running' | jq -r '.Reservations[].Instances[].InstanceId'
aws ec2 describe-instances --filters 'Name=tag:Name,Values=GWLBVPC-Appliance-10.254.12.102' 'Name=instance-state-name,Values=running' | jq -r '.Reservations[].Instances[].InstanceId'
export Appliance_11_101=$(aws ec2 describe-instances --filters 'Name=tag:Name,Values=GWLBVPC-Appliance-10.254.11.101' 'Name=instance-state-name,Values=running' | jq -r '.Reservations[].Instances[].InstanceId')
export Appliance_11_102=$(aws ec2 describe-instances --filters 'Name=tag:Name,Values=GWLBVPC-Appliance-10.254.11.102' 'Name=instance-state-name,Values=running' | jq -r '.Reservations[].Instances[].InstanceId')
export Appliance_12_101=$(aws ec2 describe-instances --filters 'Name=tag:Name,Values=GWLBVPC-Appliance-10.254.12.101' 'Name=instance-state-name,Values=running' | jq -r '.Reservations[].Instances[].InstanceId')
export Appliance_12_102=$(aws ec2 describe-instances --filters 'Name=tag:Name,Values=GWLBVPC-Appliance-10.254.12.102' 'Name=instance-state-name,Values=running' | jq -r '.Reservations[].Instances[].InstanceId')
echo "export Appliance_11_101=${Appliance_11_101}"| tee -a ~/.bash_profile
echo "export Appliance_11_102=${Appliance_11_102}"| tee -a ~/.bash_profile
echo "export Appliance_12_101=${Appliance_12_101}"| tee -a ~/.bash_profile
echo "export Appliance_12_102=${Appliance_12_102}"| tee -a ~/.bash_profile
source ~/.bash_profile
