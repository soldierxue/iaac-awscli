#!/bin/bash
set -e

### AWS Global Region 

echo "0-Setup your AWS CLI global region profile name , it will determine your aws credientials and region"

profileName="default"
targetRegion=$(aws configure get region --profile $profileName)

echo "Target Working Region: $targetRegion "

echo "Preparing IAM roles & instance profile"

ec2ssmRoleName="genshin-ssm-ec2-role"
ec2ssmProfileName="genshin-ssm-ec2-profile"

instanceIdStr=$(aws ec2 describe-instances --filters file://./ec2cfg/ec2-filter.json --query 'Reservations[*].Instances[*].[InstanceId]' --output text --profile $profileName)

find=" "
replace=","
instanceIdsComma=$(echo $instanceIdStr | sed -e "s/$find/$replace/g")

eipFilter="Name=instance-id,Values=$instanceIdsComma"

echo $eipFilter

aws ec2 describe-instances --filters file://./ec2cfg/ec2-filter.json --query 'Reservations[*].Instances[*].[InstanceId,PrivateIpAddress,Tags]' --output text --profile $profileName

echo ".....Querying the EIP for the ec2 instances"

aws ec2 describe-addresses --filters $eipFilter --query 'Addresses[*].[InstanceId,PublicIp,PrivateIpAddress]' --output text

echo "Done"