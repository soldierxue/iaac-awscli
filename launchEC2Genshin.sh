#!/bin/bash
set -e

aws configure set default.region ap-northeast-1  ### set the default aws region
targetRegion=$(aws configure get region)

echo "Target Working Region: $targetRegion "

echo "1-Prepare IAM roles & instance profile"

ec2ssmRoleName="genshin-ssm-ec2-role"
ec2ssmProfileName="genshin-ssm-ec2-profile"

roleAssociatedWithInstanceProfileOrNot=$(aws iam list-instance-profiles-for-role --role-name $ec2ssmRoleName --query 'InstanceProfiles[*].[InstanceProfileId]' --output text )

if [ -n "$roleAssociatedWithInstanceProfileOrNot" ]; then
	aws iam remove-role-from-instance-profile --instance-profile-name $ec2ssmProfileName --role-name $ec2ssmRoleName 
fi

instanceProfileExistOrNot=$(aws iam get-instance-profile --instance-profile-name $ec2ssmProfileName --query 'InstanceProfile[0].[InstanceProfileId]' --output text)

if [ -n "$instanceProfileExistOrNot" ]; then
    aws iam delete-instance-profile --instance-profile-name $ec2ssmProfileName 
fi

attachedPolicies=$(aws iam list-attached-role-policies --role-name $ec2ssmRoleName --query 'AttachedPolicies[*].[PolicyArn]' --output text )

for mgPolicy in $attachedPolicies;  do 
    echo "detach managed role policy # $mgPolicy"
    aws iam detach-role-policy --policy-arn $mgPolicy --role-name $ec2ssmRoleName 
done

roleExistOrNot=$(aws iam get-role --role-name $ec2ssmRoleName --query 'Role.[RoleName]' --output text )

if [ -n "$roleExistOrNot" ]; then
	aws iam delete-role --role-name $ec2ssmRoleName 
fi

noOutput=$(aws iam create-role --role-name $ec2ssmRoleName --assume-role-policy-document file://./ec2cfg/ssm-trustpolicy-glb.json )

noOutput=$(aws iam attach-role-policy --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess --role-name $ec2ssmRoleName )

noOutput=$(aws iam attach-role-policy --policy-arn arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM --role-name $ec2ssmRoleName )

noOutput=$(aws iam attach-role-policy --policy-arn arn:aws:iam::aws:policy/AdministratorAccess --role-name $ec2ssmRoleName )

noOutput=$(aws iam create-instance-profile --instance-profile-name $ec2ssmProfileName --profile ww)
noOutput=$(aws iam add-role-to-instance-profile --instance-profile-name $ec2ssmProfileName --role-name $ec2ssmRoleName )

echo "1-Done"


echo "1-Launch a latest version [Amazon Linux 2 - Replace with your CentoOS7.4 AMI] EC2"

imageId=$(aws ssm get-parameters --names /aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2 --query 'Parameters[0].[Value]' --output text)

echo "Latest Amazon Linux 2 AMI ID: $imageId"

result=$(aws ec2 run-instances --image-id $imageId --instance-type t3.xlarge --instance-market-options "MarketType=spot" --iam-instance-profile Name=$ec2ssmProfileName --user-data file://./ec2cfg/userdata.sh --block-device-mappings file://./ec2cfg/root-ebs-size.json --query 'Instances[*].[InstanceId, SpotInstanceRequestId]' --output text )

spotInstanceId=`echo $result | awk '{print$1}'`
spotRequestId=`echo $result | awk '{print$2}'`

echo "The launched Spot Instance Id: $spotInstanceId"
echo "The Spot Request Id: $spotRequestId"

echo "Waiting for EC2 instance to be ready"

aws ec2 wait instance-status-ok --instance-ids $spotInstanceId --profile ww

echo "EC2 is ready to use , enjoy it by SSM remote session: aws ssm start-session --target $spotInstanceId --profile $profileName"
