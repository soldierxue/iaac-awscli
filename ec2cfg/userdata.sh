#!/bin/bash
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

echo "0-YUM update with extras/epel repo & enable python3.8"
yum -y update 
yum install -y jq

ZONE="Asia/Shanghai"
sudo timedatectl set-timezone $ZONE

echo "0-Done"

echo "1-Install latest AWSCLI version 2"

if  [ -x "$(command -v aws)" ]; then
	sudo yum remove awscli -y
fi

if [ ! -d "$HOME/Downloads" ]; then
	mkdir -p $HOME/Downloads
fi
wget --quiet "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -O "$HOME/Downloads/awscliv2.zip"

cd $HOME/Downloads
unzip awscliv2.zip
./aws/install

rm -rf awscliv2.zip

echo "1-Done"

echo "2-install the docker & git"


echo "2-Done"

echo "End: user-data"