#!/bin/bash

USERID=$(id -u)
TIMESTAMP=$(date +%F-%H-%M-%S)
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOGFILE=/tmp/$SCRIPT_NAME-$TIMESTAMP.log
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

VALIDATE(){
   if [ $1 -ne 0 ]; then
        echo -e "$2...$R FAILURE $N"
        exit 1
    else
        echo -e "$2...$G SUCCESS $N"
    fi
}

if [ $USERID -ne 0 ]; then
    echo "Please run this script with root access."
    exit 1
else
    echo "You are super user."
fi

# Docker installation
echo "Installing Docker..."
yum install -y yum-utils &>> $LOGFILE
VALIDATE $? "Yum-utils installation"

yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo &>> $LOGFILE
VALIDATE $? "Docker repo addition"

yum install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y &>> $LOGFILE
VALIDATE $? "Docker installation"

systemctl start docker &>> $LOGFILE
systemctl enable docker &>> $LOGFILE
VALIDATE $? "Docker service configuration"

usermod -aG docker ec2-user &>> $LOGFILE
VALIDATE $? "User added to Docker group"

# eksctl installation
echo "Installing eksctl..."
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp &>> $LOGFILE
mv /tmp/eksctl /usr/local/bin &>> $LOGFILE
VALIDATE $? "eksctl installation"

echo "Verifying eksctl installation..."
eksctl version &>> $LOGFILE
VALIDATE $? "eksctl verification"

# kubectl installation
echo "Installing kubectl..."
curl -O https://s3.us-west-2.amazonaws.com/amazon-eks/1.30.0/2024-05-12/bin/linux/amd64/kubectl &>> $LOGFILE
chmod +x ./kubectl &>> $LOGFILE
mv kubectl /usr/local/bin/kubectl &>> $LOGFILE
VALIDATE $? "kubectl installation"

# kubens installation
echo "Installing kubens..."
git clone https://github.com/ahmetb/kubectx /opt/kubectx &>> $LOGFILE
ln -s /opt/kubectx/kubens /usr/local/bin/kubens &>> $LOGFILE
VALIDATE $? "kubens installation"

# Helm installation
echo "Installing Helm..."
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 &>> $LOGFILE
chmod 700 get_helm.sh &>> $LOGFILE
./get_helm.sh &>> $LOGFILE
VALIDATE $? "Helm installation"

echo "All installations completed successfully!"
