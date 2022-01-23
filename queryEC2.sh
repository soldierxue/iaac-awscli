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

# The launched Instance Id of genshin.1.internal.com is : i-0e378467702af9350
# The launched Instance Id of genshin.2.internal.com is : i-03d5840d419b0abaa
# The launched Instance Id of genshin.3.internal.com is : i-06d2bc6f5f46fcb6b
# The launched Instance Id of genshin.4.internal.com is : i-05d4da2e4416fb49e


# aws ec2 describe-addresses --filters "Name=instance-id,Values=[i-0576a33832a46775b,i-00160e24beb22189a]" --query 'Addresses[*].[InstanceId,PublicIp,PrivateIpAddress]' --output text 