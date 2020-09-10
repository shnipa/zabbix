output "SSH" {
  value = "ssh epam@${google_compute_instance.ldap-instance.network_interface.0.access_config.0.nat_ip}"
}

output "app" {
  value = "http://${google_compute_instance.ldap-instance.network_interface.0.access_config.0.nat_ip}/ldapadmin/"
}
