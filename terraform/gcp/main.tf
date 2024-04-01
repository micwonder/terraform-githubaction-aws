variable "project_id" {
  description = "The GCP project id"
  type        = string
}
variable "region" {
  default     = "us-central1"
  description = "GCP region"
  type        = string
}
variable "namespace" {
  description = "The namespace for resource naming"
  type        = string
}

## To add a repo, append the default here
variable "repos" {
  description = "GCP Source Repos"
  type        = list(string)
  default     = ["pwa", "cms"]
}

output "repos" {
  value = [
    for repo in var.repos:
    google_sourcerepo_repository.repos[repo].id
  ]
}

output "urls" {
  value = [for repo in var.repos:
    {
    repo = google_sourcerepo_repository.repos[repo].url
    app  = google_cloud_run_service.service.status[0].url
    }
  ]
}

locals {
  services = [
    "sourcerepo.googleapis.com",
    "cloudbuild.googleapis.com",
    "run.googleapis.com",
    "iam.googleapis.com",
  ]
}

provider "google" {
  credentials = file("access.json")
  project     = var.project_id
  region      = var.region
}

resource "google_project_service" "enabled_service" {
  for_each = toset(local.services)
  project  = var.project_id
  service  = each.key
  provisioner "local-exec" {
    command = "sleep 60"
  }
  provisioner "local-exec" {
    when    = destroy
    command = "sleep 15"
  }
}

resource "google_sourcerepo_repository" "repos" {
  depends_on = [
    google_project_service.enabled_service["sourcerepo.googleapis.com"]
  ]
  for_each                 = toset(var.repos)  
  name       = "${var.namespace}-${each.value}"
}

resource "google_project_iam_member" "cloudbuild_roles" {
  depends_on = [google_cloudbuild_trigger.trigger]
  for_each   = toset(["roles/run.admin", "roles/iam.serviceAccountUser"])
  project    = var.project_id
  role       = each.key
  member     = "serviceAccount:${@cloudbuild.gserviceaccount.com>data.google_project.project.number}@cloudbuild.gserviceaccount.com"
}

resource "google_cloud_run_service" "service" {
  depends_on = [
    google_project_service.enabled_service["run.googleapis.com"]
  ]
  name     = var.namespace
  location = var.region
template {
    spec {
      containers {
        image = "us-docker.pkg.dev/cloudrun/container/hello"
      }
    }
  }
}

data "google_iam_policy" "admin" {
  binding {
    role = "roles/run.invoker"
    members = [
      "allUsers",
    ]
  }
}
resource "google_cloud_run_service_iam_policy" "policy" {
  location    = var.region
  project     = var.project_id
  service     = google_cloud_run_service.service.name
  policy_data = data.google_iam_policy.admin.policy_data
}

