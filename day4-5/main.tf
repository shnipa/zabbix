provider "google" {
  credentials = file("weighty-forest-288021-a66f9faea241.json")
  project     = var.project
  region      = var.region
}

resource "google_compute_instance" "zabbix-server" {
  name         = "${var.name}-server"
  machine_type = var.machine_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = var.image
    }
  }

  network_interface {
    network = var.network
    access_config {
    }
  }

  metadata_startup_script = file("srv.sh")
}

resource "google_compute_instance" "zabbix-agent" {
  name         = "${var.name}-agent"
  machine_type = var.machine_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = var.image
    }
  }

  network_interface {
    network = var.network
    access_config {
    }
  }

#  depends_on = [google_compute_instance.ldap-server]
  metadata_startup_script = templatefile("agent.sh", {srv_ip = google_compute_instance.zabbix-server.network_interface.0.network_ip})
}

