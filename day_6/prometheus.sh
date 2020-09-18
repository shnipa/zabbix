#!/bin/bash
sudo setenforce 0
sudo sed -i 's/^SELINUX=.*/SELINUX=permissive/g' /etc/selinux/config

###docker###

sudo yum install -y yum-utils device-mapper-persistent-data lvm2
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sudo yum install -y docker-ce
sudo usermod -aG docker $(whoami)
newgrp docker
sudo systemctl enable --now docker

###docker-compose###

sudo yum install -y epel-release
sudo yum install -y python-pip python-devel gcc
sudo yum install -y python3-pip
sudo pip3 install docker-compose
sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
sudo pip install --upgrade pip
sudo systemctl start docker
sudo mkdir prometheus
sudo mkdir alertmanager
sudo mkdir blackbox

hostname -i > srv-node-ip

###configs###

sudo cat > ./prometheus/prometheus.yml <<EOF
global:
  scrape_interval:     15s 
  evaluation_interval: 15s 
  scrape_timeout: 15s

  external_labels:
      monitor: 'my-project'
scrape_configs:
  - job_name: node
    scrape_interval: 5s
    static_configs:
    - targets: ['$(cat srv-node-ip):9100','${cli_node_ip}:9100']
    
  - job_name: 'blackbox'
    metrics_path: /probe
    params:
      module: [http_2xx] 
    tls_config:
      insecure_skip_verify: true
    static_configs:
      - targets:
        - https://tut.by
    relabel_configs:
      - source_labels: [__address__]
        target_label: __param_target
      - source_labels: [__param_target]
        target_label: instance
      - target_label: __address__
        replacement: "$(cat srv-node-ip):9115" 
EOF

sudo cat > ./prometheus/alert.rules <<EOF
groups:
- name: test
  rules:

  - alert: service_down
    expr: up == 0
    for: 30s
    labels:
      severity: page
    annotations:
      summary: "Instance {{ $labels.instance }} down"
      description: "{{ $labels.instance }} of job {{ $labels.job }} has been down for more than 30 seconds."

  - alert: high_load
    expr: node_load1 > 0.8
    for: 30s
    labels:
      severity: page
    annotations:
      summary: "Instance {{ $labels.instance }} under high load"
      description: "{{ $labels.instance }} of job {{ $labels.job }} is under high load."

  - alert: site_down
    expr: probe_success < 1
    for: 30s
    labels:
      severity: page
    annotations:
      summary: "Site Down: {{$labels.instance}}"
      description: "Site Down: {{$labels.instance}} for more than 30 seconds"
EOF

# config for alertmanager
sudo cat > ./alertmanager/config.yml <<EOF
route:
    receiver: 'pager'

receivers:
    - name: 'pager'
      webhook_configs:
      - url: https://onliner.by
EOF

# config for blackbox
sudo cat > ./blackbox/config.yml <<EOF
modules:
  http_2xx:
    prober: http
    timeout: 5s
    http:
      valid_http_versions: ["HTTP/1.1", "HTTP/2"]
      valid_status_codes: []  # Defaults to 2xx
      method: GET
      no_follow_redirects: false
      fail_if_ssl: false
      fail_if_not_ssl: false
      fail_if_matches_regexp:
        - "Could not connect to database"
      tls_config:
        insecure_skip_verify: true
      preferred_ip_protocol: "ip4" # defaults to "ip6"
EOF

# create docker-compose file
sudo cat > ./docker-compose.yml <<EOF
version: "3.1"
services:
  prometheus:
    image: prom/prometheus:v2.1.0
    restart: always
    volumes:
      - ./prometheus:/etc/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--web.console.libraries=/usr/share/prometheus/console_libraries'
      - '--web.console.templates=/usr/share/prometheus/consoles'
      - '--web.enable-lifecycle'
    ports:
      - 9090:9090
    deploy:
      mode: global
    
  grafana:
    image: grafana/grafana
    restart: always
    depends_on:
      - prometheus
    ports:
      - 3000:3000
      
  node-exporter:
    image: prom/node-exporter
    ports:
      - 9100:9100
    restart: always
    deploy:
      mode: global  
      
  alertmanager:
    image: prom/alertmanager:v0.12.0
    restart: always
    volumes:
      - ./alertmanager/:/etc/alertmanager/
    command:
      - '-config.file=/etc/alertmanager/config.yml'
      - '-storage.path=/alertmanager'
    ports:
      - 9093:9093
    deploy:
      mode: global
      
  blackbox_exporter:
    image: prom/blackbox-exporter:v0.10.0
    restart: always
    volumes:
      - ./blackbox:/etc/blackboxexporter/
    command:
      - '--config.file=/etc/blackboxexporter/config.yml'
    ports:
      - 9115:9115
EOF

docker-compose up -d