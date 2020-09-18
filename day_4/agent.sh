#!/bin/bash

sudo su

setenforce 0
# install and setup zabbix-agent
rpm -Uvh https://repo.zabbix.com/zabbix/4.4/rhel/7/x86_64/zabbix-release-4.4-1.el7.noarch.rpm
yum -y install zabbix-agent
sed -i.backup -e "/^Server=.*/c\Server=${srv_ip}" /etc/zabbix/zabbix_agentd.conf
sed -i.backup -e "/^ServerActive=.*/c\ServerActive=${srv_ip}" /etc/zabbix/zabbix_agentd.conf
sed -i.backup -e "/^Hostname=.*/c\Hostname=zabbix-agent" /etc/zabbix/zabbix_agentd.conf

# configuring firewall
firewall-cmd --add-port={10051/tcp,10050/tcp} --permanent
firewall-cmd --reload

# running zabbix-agent
systemctl enable zabbix-agent && systemctl start zabbix-agent