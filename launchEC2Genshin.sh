#!/bin/bash
set -e

### AWS Global Region 

echo "0-Setup your AWS CLI global region profile name , it will determine your aws credientials and region"

profileName="default"
targetRegion=$(aws configure get region --profile $profileName)

echo "Target Working Region: $targetRegion "

ec2ssmRoleName="genshin-ssm-ec2-role"
ec2ssmProfileName="genshin-ssm-ec2-profile"

echo "2-Launch EC2 instances"

aws iam wait instance-profile-exists --instance-profile-name $ec2ssmProfileName --profile $profileName

imageId=$(aws ssm get-parameters --names /aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2 --query 'Parameters[0].[Value]' --output text --profile $profileName)

echo "AMI ID: $imageId"
instanceType=t3.xlarge

i=1
for index in 1 2 3 4
do 
    instanceName="genshin."$index".internal.com"
    tags="ResourceType=instance,Tags=[{Key=Name,Value="$instanceName"}]"
    result=$(aws ec2 run-instances --image-id $imageId --instance-type $instanceType --iam-instance-profile Name=$ec2ssmProfileName --user-data file://./ec2cfg/userdata.sh --block-device-mappings file://./ec2cfg/root-ebs-size.json --tag-specifications $tags --query 'Instances[*].[InstanceId]' --output text --profile $profileName)
    instanceId=`echo $result | awk '{print$1}'`
    echo "The launched Instance Id of $instanceName is : $instanceId"
done

echo "Done."