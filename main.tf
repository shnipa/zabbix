provider "google" {
  project       = var.project   
  region        = "us-central1"
  zone          = "us-central1-c"
}

resource "google_compute_instance" "ldap-instance" {
  name         = "LDAP-1"
  machine_type = "n1-standard-1"
  tags         = ["http-server", "https-server"]

  boot_disk {
    initialize_params {
      image = "centos-cloud/centos-7"
    }
  }

  provisioner "file" {
    connection {
      host = google_compute_instance.ldap-instance.network_interface.0.access_config.0.nat_ip
      type = "ssh"
      user = "epam"
      private_key = file(var.private_key) 
      agent = "false"
    }
  }

  metadata = {
    ssh-keys = "epam:${file(var.public_key)}"
  }

  metadata_startup_script = file("script.sh")
    
  network_interface {
    network = "default"
    access_config {}
  }
}
