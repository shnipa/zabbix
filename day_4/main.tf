provider "google" {
  credentials = file("weighty-forest-288021-a66f9faea241.json")
  project     = var.project
  region      = var.region
}

resource "google_compute_instance" "ek-server" {
  name         = "${var.name}"
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

  metadata_startup_script = templatefile("elkServ.sh", {
    ek_server = "${var.name}" 
  })
}

resource "google_compute_instance" "tomcat" {
  name         = "client-tomcat"
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

  
  metadata_startup_script = templatefile("startTomcat.sh", {
    ek_server = "${var.name}" 
  })
}

