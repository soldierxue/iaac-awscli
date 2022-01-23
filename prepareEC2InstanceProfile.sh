#!/bin/bash
set -e

### AWS Global Region 

echo "0-Setup your AWS CLI global region profile name , it will determine your aws credientials and region"

profileName="default"
aws sts get-caller-identity --profile $profileName
targetRegion=$(aws configure get region --profile $profileName)

echo "Target Working Region: $targetRegion "

echo "1-Preparing IAM roles & instance profile"

ec2ssmRoleName="genshin-ssm-ec2-role"
ec2ssmProfileName="genshin-ssm-ec2-profile"

noOutput=$(aws iam create-role --role-name $ec2ssmRoleName --assume-role-policy-document file://./ec2cfg/ssm-trustpolicy-glb.json --profile $profileName)

noOutput=$(aws iam attach-role-policy --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess --role-name $ec2ssmRoleName --profile $profileName)

noOutput=$(aws iam attach-role-policy --policy-arn arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM --role-name $ec2ssmRoleName --profile $profileName)

noOutput=$(aws iam attach-role-policy --policy-arn arn:aws:iam::aws:policy/AdministratorAccess --role-name $ec2ssmRoleName --profile $profileName)

noOutput=$(aws iam create-instance-profile --instance-profile-name $ec2ssmProfileName --profile ww)
noOutput=$(aws iam add-role-to-instance-profile --instance-profile-name $ec2ssmProfileName --role-name $ec2ssmRoleName --profile $profileName)

echo "1-Done"