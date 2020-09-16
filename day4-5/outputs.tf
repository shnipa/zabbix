output "zabbix" {
  value = "http://${google_compute_instance.zabbix-server.network_interface[0].access_config[0].nat_ip}/zabbix"
}
