#!/bin/bash

sudo yum install java-1.8.0-openjdk -y
rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch

cat > /etc/yum.repos.d/elasticsearch.repo <<EOF
[elasticsearch]
name=Elasticsearch repository for 7.x packages
baseurl=https://artifacts.elastic.co/packages/7.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=0
autorefresh=1
type=rpm-md
EOF

sudo yum install -y --enablerepo=elasticsearch elasticsearch
sudo systemctl start elasticsearch

cat > /etc/yum.repos.d/kibana.repo <<EOF
[kibana-7.x]
name=Kibana repository for 7.x packages
baseurl=https://artifacts.elastic.co/packages/7.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=1
autorefresh=1
type=rpm-md
EOF

sudo yum install -y kibana
cat >> /etc/kibana/kibana.yml <<EOF
server.host: "0.0.0.0"
EOF

sudo systemctl enable kibana
sudo systemctl start kibana
sleep 180

cat >> /etc/elasticsearch/elasticsearch.yml <<EOF
network.host: 0.0.0.0
http.port: 9200
discovery.seed_hosts: ["0.0.0.0"]
EOF

sudo systemctl enable elasticsearch
sudo systemctl restart elasticsearch

cat > /tmp/tomcat_replicas_0.sh <<EOF
#!/bin/bash
curl -XPUT 'http://${ek_server}:9200/logstash-$(date +%Y.%m.%d)-000001/_settings' -H 'Content-Type: application/json' -d '
{
    "index" : {
        "number_of_replicas" : 0
    }
}'
EOF
chmod +x /tmp/tomcat_replicas_0.sh
sleep 360
/tmp/tomcat_replicas_0.sh