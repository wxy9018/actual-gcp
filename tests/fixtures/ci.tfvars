# Dummy values for local validation / terraform console only (no real GCP resources).
gcp_project_name            = "ci-validation-project"
gcp_billing_project_name    = "ci-validation-project"
gcp_region                  = "us-central1"
gcp_zone                    = "us-central1-c"
actual_fqdn                 = "ci.example.duckdns.org"
duckdns_subdomains          = "ci"
duckdns_token               = "ci-token-not-real"
user                        = "ciuser"
public_key_path             = "/nonexistent/ci.pub"
vm_size                     = "e2-micro"
vm_image_family             = "cos-117-lts"
vm_image_project            = "cos-cloud"
container_host_network_tags = ["allow-ssh-proxy", "https-server", "http-server"]
project_enabled_services = [
  "cloudbilling.googleapis.com",
  "cloudresourcemanager.googleapis.com",
  "compute.googleapis.com",
  "iam.googleapis.com",
  "networkmanagement.googleapis.com",
]
