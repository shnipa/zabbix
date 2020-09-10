provider "google" {
  credentials = "weighty-forest-288021-a66f9faea241.json"
  project     = var.project
  region      = var.region
}

resource "google_compute_instance" "ldap-server" {
  name         = "${var.name}-server"
  machine_type = var.machine_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = var.image
    }
  }

  network_interface {
    network = "default"
    access_config {
    }
  }

  metadata_startup_script = file("srv.sh")
}

resource "google_compute_instance" "ldap-client" {
  name         = "${var.name}-client"
  machine_type = var.machine_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = var.image
    }
  }

  network_interface {
    network = "default"
    access_config {}
  }

  metadata_startup_script = templatefile("cl.sh", {int_ip = google_compute_instance.ldap-server.network_interface.0.network_ip})
}

