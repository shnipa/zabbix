output "kibana" {
  value = "http://${google_compute_instance.ek-server.network_interface[0].access_config[0].nat_ip}:5601"
}

output "elasticSearch" {
  value = "http://${google_compute_instance.ek-server.network_interface[0].access_config[0].nat_ip}:9200"
}

output "tomcat" {
  value = "http://${google_compute_instance.tomcat.network_interface[0].access_config[0].nat_ip}:8080"
}