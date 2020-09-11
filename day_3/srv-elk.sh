#!/bin/bash
yum install -y java-11-openjdk-devel 
yum install -y wget 

rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch
cat > /etc/yum.repos.d/logstash.repo << EOT
[logstash-7.x]
name=Elastic repository for 7.x packages
baseurl=https://artifacts.elastic.co/packages/7.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=1
autorefresh=1
type=rpm-md
EOT
yum install -y logstash 
cat > /etc/logstash/conf.d/ls.conf << EOF
input {
  file {
    path => “/path/to/log"
    start_position => "beginning"
  }
}

output {
  elasticsearch {
    hosts => ["localhost:9200"]
  }
  stdout { codec => rubydebug }
}
EOF
systemctl enable logstash
systemctl start logstash

wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-7.9.1-x86_64.rpm
sudo rpm --install elasticsearch-7.9.1-x86_64.rpm
systemctl start elasticsearch.service
rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch

cat > /etc/yum.repos.d/kibana.repo << EOT
[kibana-7.x]
name=Kibana repository for 7.x packages
baseurl=https://artifacts.elastic.co/packages/7.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=1
autorefresh=1
type=rpm-md
EOT
yum install -y kibana 
echo -e '\nserver.port: 5601\nserver.host: "0.0.0.0"' >> /etc/kibana/kibana.yml
systemctl enable kibana
systemctl start kibana