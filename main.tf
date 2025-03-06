provider "github" {
  token = "${{ secrets.PAT }}"
}

resource "github_repository" "repo" {
  name        = "my-repo"
  description = "Repository managed by Terraform"
  visibility  = "private"
}

resource "github_repository_collaborator" "collaborator" {
  repository = github_repository.repo.name
  username   = "softservedata"
  permission = "push"
}


resource "github_branch" "develop" {
  repository = github_repository.repo.name
  branch     = "develop"
}

resource "github_repository" "update_default_branch" {
  name           = github_repository.repo.name
  default_branch = github_branch.develop.branch
}


resource "github_branch_protection" "develop_protection" {
  repository_id = github_repository.repo.node_id
  pattern       = "develop"
  required_pull_request_reviews {
    required_approving_review_count = 2
  }
  enforce_admins = false
}


resource "github_branch_protection" "main_protection" {
  repository_id = github_repository.repo.node_id
  pattern       = "main"
  required_pull_request_reviews {
    required_approving_review_count = 1
  }
  enforce_admins = false
}


resource "github_repository_file" "codeowners" {
  repository          = github_repository.repo.name
  file                = ".github/CODEOWNERS"
  content             = "* @softservedata"
  overwrite_on_create = true
}


resource "github_repository_file" "pull_request_template" {
  repository          = github_repository.repo.name
  file                = ".github/pull_request_template.md"
  content             = <<EOT
  ## Describe your changes
  ## Issue ticket number and link

  ## Checklist before requesting a review
  - [ ] I have performed a self-review of my code
  - [ ] If it is a core feature, I have added thorough tests
  - [ ] Do we need to implement analytics?
  - [ ] Will this be part of a product update? If yes, please write one phrase about this update
  EOT
  overwrite_on_create = true
}


resource "github_repository_deploy_key" "deploy_key" {
  repository = github_repository.repo.name
  title      = "DEPLOY_KEY"
  key        = "${{ secrets.DEPLOY_KEY }}"
  read_only  = false
}


resource "github_actions_secret" "pat_secret" {
  repository      = github_repository.repo.name
  secret_name     = "PAT"
  plaintext_value = "${{ secrets.PAT }}"
}


resource "github_repository_webhook" "discord_webhook" {
  repository = github_repository.repo.name
  configuration {
    url          = "${{ secrets.DISCORD_WEBHOOK_URL }}"
    content_type = "json"
    insecure_ssl = false
  }
  events = ["pull_request"]
}
