#!/bin/bash
startuptime1=$(date +%s%3N)

while getopts ":i:a:c:r:" opt; do
  case $opt in
    i) docker_image="$OPTARG"
    ;;
    a) storage_account="$OPTARG"
    ;;
    c) container_name="$OPTARG"
    ;;
    r) resource_group="$OPTARG"
    ;;
    p) port="$OPTARG"
    ;;

t) script_file="$OPTARG"
    ;;
    \?) echo "Invalid option -$OPTARG" >&2
    ;;
  esac
done

if [ -z $docker_image ]; then
    docker_image="azuresdk/azure-cli-python:latest"
fi

if [ -z $script_file ]; then
    script_file="writeblob.sh"
fi

for var in storage_account resource_group
do

    if [ -z ${!var} ]; then
        echo "Argument $var is not set" >&2
        exit 1
    fi 

done

# Install Docker and then run docker image with cli

sudo apt-get -y update
sudo apt-get -y install linux-image-extra-$(uname -r) linux-image-extra-virtual
sudo apt-get -y update
sudo apt-get -y install apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt-get -y update

#Install Azure CLI
AZ_REPO=$(lsb_release -cs)
echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $AZ_REPO main" | \
     sudo tee /etc/apt/sources.list.d/azure-cli.list
sudo apt-key adv --keyserver packages.microsoft.com --recv-keys 52E16F86FEE04B979B07E28DB02C46DF417A0893
sudo apt-get install apt-transport-https
sudo apt-get update && sudo apt-get install azure-cli

sudo apt-get -y update
sudo apt-get install cifs-utils

sudo apt-get -y update
sudo apt install git-all

today=$(date +%Y-%m-%d)
sudo mkdir /mnt/azurefiles
sudo mount -t cifs //acrtestlogs.file.core.windows.net/logshare /mnt/azurefiles -o vers=3.0,username=acrtestlogs,password=ZIisPCN0UrjLfhv6Njiz0Q8w9YizeQgIm6+DIfMtjak4RJrRlzJFn4EcwDUhNvXmmDv5Axw9yGePh3vn1ak8cg==,dir_mode=0777,file_mode=0777,sec=ntlmssp
sudo mkdir /mnt/azurefiles/$today

startuptime2=$(date +%s%3N)
sleeptime=$((600-(startuptime2-startuptime1)/1000))
sleep $sleeptime

echo "---docker pull dotnet from eus.mcr.microsoft.com---"

git clone https://github.com/SteveLasker/node-helloworld.git
cd node-helloworld
az login -u <username> -p <password>
az acr build -t helloworld:v1 --context . -r $ACR_NAME


pullbegin=$(date +%s%3N)
PullStartTime=$(date +%H:%M:%S)
sudo docker pull eus.mcr.microsoft.com/dotnet
pullend=$(date +%s%3N)
PullEndTime=$(date +%H:%M:%S)
pulltime=$((pullend-pullbegin))
echo "---nslookup eus.mcr.microsoft.com---"
nslookup=$(nslookup eus.mcr.microsoft.com)
echo registry,region,starttime,endtime,pulltime:eus.mcr.microsoft.com,eastus,$PullStartTime,$PullEndTime,$pulltime >> /mnt/azurefiles/$today/mcr-output.log
echo $nslookup >> /mnt/azurefiles/$today/mcr-output.log
echo "Done"
