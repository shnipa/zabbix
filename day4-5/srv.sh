#!/bin/bash
setenforce 0

#database default name "zabbix"
#database pass at var $db_pass
#############################

#database pass
db_pass="z@bbix"

# update system
yum -y update 

# install repo
yum -y install epel-release

# install zabbix
rpm -Uvh https://repo.zabbix.com/zabbix/4.4/rhel/7/x86_64/zabbix-release-4.4-1.el7.noarch.rpm
yum -y install zabbix-server-mysql zabbix-web-mysql zabbix-agent

# install httpd
yum -y install httpd

# install and setup php
yum -y install php php-pear php-cgi php-common php-mbstring php-snmp php-gd php-xml php-mysql php-gettext php-bcmath
sed -i.backup -e 's/max_execution_time.*/max_execution_time = 300/g' /etc/php.ini
sed -i.backup -e 's/memory_limit.*/memory_limit = 128M/g' /etc/php.ini
sed -i.backup -e 's/post_max_size.*/post_max_size = 16M/g' /etc/php.ini
sed -i.backup -e 's/upload_max_filesize.*/upload_max_filesize = 2M/g' /etc/php.ini
sed -i.backup -e 's/max_input_time.*/max_input_time = 600/g' /etc/php.ini
sed -i.backup -e '/.*max_input_vars.*/c\max_input_vars = 10000' /etc/php.ini
sed -i.backup -e 's/;date.timezone.*/date.timezone = Europe\/Minsk/g' /etc/php.ini

# install and setup database
yum -y install mariadb-server
systemctl enable mariadb && systemctl start mariadb
mysql -uroot -e "SET PASSWORD FOR root@localhost = PASSWORD('root');"
mysql -uroot -proot <<EOF
    create database zabbix character set utf8 collate utf8_bin;
    create user 'zabbix'@'localhost' identified by '${db_pass}';
    grant all privileges on zabbix.* to 'zabbix'@'localhost' identified by '${db_pass}';
EOF
zcat /usr/share/doc/zabbix-server-mysql*/create.sql.gz | mysql -uzabbix -p${db_pass} zabbix
sed -i.backup -e "/# DBPassword.*/a\\\nDBPassword = ${db_pass}" /etc/zabbix/zabbix_server.conf
sed -i.backup -e '/# DBHost.*/a\\nDBHost = localhost' /etc/zabbix/zabbix_server.conf

systemctl enable httpd && systemctl start httpd

systemctl enable zabbix-server && systemctl start zabbix-server && systemctl start zabbix-agent

# configuring firewall
firewall-cmd --add-port={10051/tcp,10050/tcp} --permanent
firewall-cmd --add-port={80/tcp,443/tcp} --permanent
firewall-cmd --reload

#parsing a log file
chgrp zabbix /var/log/secure 
chmod 640 /var/log/secure 
