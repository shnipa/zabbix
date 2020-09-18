provider "google" {
  credentials = file("weighty-forest-288021-a66f9faea241.json")
  project     = var.project
  region      = var.region
}

provider "datadog" {
  api_key = var.api_key
  app_key = var.app_key
  api_url = var.api_url
}

resource "google_compute_address" "external" {
  name = "external"
}

resource "google_compute_instance" "tomcat" {
  name         = "${var.name}-tomcat"
  machine_type = var.default_machine_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = var.image
    }
  }

  network_interface {
    network = "default"
    access_config {
      nat_ip = google_compute_address.external.address
    }
  }

  metadata_startup_script = templatefile("tomcat.sh", {api_key = var.api_key, ext_ip = google_compute_address.external.address})
}

resource "datadog_monitor" "tomcat" {
  name               = "tomcat state"
  type               = "metric alert"
  message            = "Tomcat is down"
  escalation_message = "Tomcat is down"

  thresholds = {
    alert = 1
  }

  notify_no_data    = false
  renotify_interval = 60

  lifecycle {
    ignore_changes = [silenced]
  }
}
