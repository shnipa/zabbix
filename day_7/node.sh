#!/bin/bash
# conf selinux
sudo setenforce 0
sudo sed -i 's/^SELINUX=.*/SELINUX=permissive/g' /etc/selinux/config

# install docker
sudo yum install -y yum-utils device-mapper-persistent-data lvm2
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sudo yum install -y docker-ce
sudo usermod -aG docker $(whoami)
newgrp docker
sudo systemctl enable --now docker

# install docker-compose
sudo yum install -y epel-release
sudo yum install -y python-pip python-devel gcc
sudo yum install -y python3-pip
sudo pip3 install docker-compose
sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
sudo pip install --upgrade pip
sudo systemctl start docker

# create docker-compose file
sudo cat > ./docker-compose.yml <<EOF
version: "3.1"
services:

  node-exporter:
    image: prom/node-exporter
    ports:
      - 9100:9100
    restart: always
    deploy:
      mode: global  
      
EOF

docker-compose up -d