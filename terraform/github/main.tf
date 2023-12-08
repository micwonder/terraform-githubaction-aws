provider "github" {
  owner = var.owner
  token = var.github_token
}

data "github_team" "admins" {
  slug = "lumeo-admins"
}

data "github_team" "triage" {
  slug = "lumeo-triage"
}

data "github_team" "readonly" {
  slug = "lumeo-readonly"
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
    { name="lumeo-readonly", description = "Read-only access (default)" },
    { name="lumeo-admin", description = "administrative access" }
  ]
}

variable "members" {
  description = "Authorized Github users"
  type = list(object({
            username = string,
            role = string,
            teams = list(string)
  }))

  default = [
    { username = "denzuko", role = "owner", teams = ["lumeo-triage", "lumeo-readonly"] },
    { username = "DontaeL", role = "owner", teams = ["lumeo-triage", "lumeo-readonly"] },
    { username = "Greg-Lumeo", role = "member", teams = ["lumeo-triage", "lumeo-readonly"] },
    { username = "SimzBochner37', role = "member", teams = ["lumeo-triage", "lumeo-readonly"] },
    { username = "mjalpha", role = "member", teams = ["lumeo-triage", "lumeo-readonly"] }
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

resource "github_membership" "all" {
  for_each var.members
  username = each.username
  role = each.role
}


resource "github_team_members" "readonly" {
  for_each  var.members
  team_id  = github_team.readonly.id

  members {
    username = each.username
    role     = each.role
  }

}

resource "github_repository" "repos" {

  for_each var.repos
  
  name      = each.name
  description = each.description
  
  visibility = "private"
  auto_init = true
  permissions = "pull"
  
}

resource "github_repository_tag_protection" "all" {

  for_each var.repos
  
  repository      = each.name
  pattern         = "v*"
}

resource "github_branch_protection_v3" "all" {
  for_each       vars.repos
  
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
    dismissal_users       = ["denzuko"]
    dismissal_teams       = [github_team.admin.slug]
    dismissal_app         = []
    

    bypass_pull_request_allowances {
      users = []
      teams = [github_team.admin.slug]
      apps  = []
    }
  }

  restrictions {
    users = [] 
    teams = [github_team.admin.slug]
    apps  = []
  }
}

resource "github_team_repository" "alladmin" {
  for_each  vars.repos
  team_id    = github_team.admin.id
  repository = each.repos.name
  permission = "pull"
}
