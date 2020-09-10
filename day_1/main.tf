provider "google" {
  project       = var.project   
  region        = "us-central1"
  zone          = "us-central1-c"
}

resource "google_compute_instance" "ldap-instance" {
  name         = "ldap-1"
  machine_type = "n1-standard-1"
  tags         = ["http-server", "https-server"]

  boot_disk {
    initialize_params {
      image = "centos-cloud/centos-7"
    }
  }

  metadata_startup_script = file("script.sh")
    
  network_interface {
    network = "default"
    access_config {}
  }
}
