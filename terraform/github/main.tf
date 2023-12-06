provider "github" {
  owner = var.owner
  token = var.github_token
}

data "github_team" "admins" {
  slug = "admins"
}

data "github_team" "programmers" {
  slug = "programmers"
}

locals {
  teams = [data.github_team.owners.id, data.github_team.editors.id]
}

variable "owner" {
  description = "GitHub owner used to configure the provider"
  type        = string
}

variable "github_token" {
  description = "GitHub access token used to configure the provider"
  type        = string
}

varaible "teams" {
  description = "Github org teams"
  type        = list(object({
      name    = string,
      description = string }))
  default = [
    { name="lumeo-product", description = "" },
    { name="lumeo-triage", description = "Contains everybody in the org. Grants triage access to all repos" },
    { name="lumeo-readonly", description = "Read-only access (default)" }
  ]
}

variable "members" {
  description = "Authorized Github users"
  type = list(object({
      username = string,
      role = string
      }))
  default = [
  { username = "denzuko", role = "owner" },
  { username = "DontaeL", role = "owner" },
  { username = "Greg-Lumeo", role = "member" },
  { username = "SimzBochner37', role = "member" },
  { username = "mjalpha", role = "member" }
  ]
}

variable "repos" {
  description = "Project Repositories"
  type = list(object({
    name = string,
    descriptin = string
  }))

  default = [
    { name = "LumeoAI", description = "Lumeo AI Project management space" }
  ]
}

resource "github_membership" "teammembers" {
  for_each var.members
  username = each.username
  role = each.role
}

resource "github_repository" "repos" {

  for_each var.repos
  
  name      = each.name
  description = each.description
  
  visibility = "private"
  auto_init = true
  permissions = "pull"
  
}

resource "github_repository_tag_protection" "tagprotections" {

  for_each var.repos
  
    repository      = each.name
    pattern         = "v*"
}

resource "github_branch_protection_v3" "branchprotections" {
  for_each vars.repos
  
  repository     = vars.repos.name
  branch         = "main"
  enforce_admins = true

  required_status_checks {
    strict   = false
    checks = [
      "ci/tests"
    ]
  }

  require_signed_commits = true
  
  required_pull_request_reviews {
    dismiss_stale_reviews = true
    dismissal_users       = ["foo-user"]
    dismissal_teams       = [github_team.example.slug]
    dismissal_app         = ["foo-app]
    

    bypass_pull_request_allowances {
      users = ["foo-user"]
      teams = [github_team.example.slug]
      apps  = ["foo-app"]
    }
  }

  restrictions {
    users = for_each u in var.members: 
    teams = [github_team.example.slug]
    apps  = ["foo-app"]
  }
}
