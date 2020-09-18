
provider "google" {
  credentials = file("weighty-forest-288021-a66f9faea241.json")
  project     = var.project
  region      = var.region
}

resource "google_compute_instance" "node" {
  name         = "node"
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

  metadata_startup_script = file("node.sh")
}

locals {
  node_ip = google_compute_instance.node.network_interface.0.network_ip
}

resource "google_compute_instance" "prometheus" {
  name         = "prometheus"
  machine_type = var.machine_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = var.image
    }
  }

  network_interface {
    network = var.network
    access_config {}
  }

  metadata_startup_script = templatefile("prometheus.sh", {
    cli_node_ip = "${local.node_ip}" })
}

