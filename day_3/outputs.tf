output "tomcat" {
  value = "http://${google_compute_instance.tomcat.network_interface[0].access_config[0].nat_ip}:8080"
}
output "kibana" {
  value = "http://${google_compute_instance.ek-srv.network_interface[0].access_config[0].nat_ip}:5601"
}