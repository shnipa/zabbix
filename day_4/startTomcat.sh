#!/bin/bash

sudo yum install -y java-1.8.0-openjdk
sudo yum install -y tomcat wget tomcat-admin-webapps tomcat-docs-webapp tomcat-javadoc tomcat-webapps

sudo rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch

sudo cat > /etc/yum.repos.d/logstash.repo <<EOF
[logstash-7.x]
name=Elastic repository for 7.x packages
baseurl=https://artifacts.elastic.co/packages/7.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=1
autorefresh=1
type=rpm-md
EOF

sudo yum install -y logstash

sudo cat > /etc/logstash/conf.d/logstash.conf <<EOF
input {
	file {
		path => "/usr/share/tomcat/logs/*"
		start_position => "beginning"
		type => "tomcat_logs"
	}
}

output {
	elasticsearch {
		hosts => ["${ek_server}:9200"]
	}
	stdout { codec => rubydebug}
}
EOF

echo "path.config: \"/etc/logstash/conf.d/*.conf\"" >> /etc/logstash/logstash.yml


wget -P /var/lib/tomcat/webapps/ https://tomcat.apache.org/tomcat-7.0-doc/appdev/sample/sample.war

chown tomcat:tomcat /var/lib/tomcat/webapps/sample.war
sudo chmod 775 /var/lib/tomcat/webapps/sample.war
sudo chmod 775 -R /usr/share/tomcat/logs/

sudo systemctl enable logstash
sudo systemctl enable tomcat

sudo systemctl start tomcat
sleep 300
sudo systemctl start logstash