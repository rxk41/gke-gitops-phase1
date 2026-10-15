# Billing guardrail. Existing projects should be imported before Terraform manages billing.
data "google_project" "current" {
  project_id = var.project_id
}
resource "google_project" "billing" {
  count           = var.manage_project_billing ? 1 : 0
  project_id      = var.project_id
  name            = data.google_project.current.name
  billing_account = var.billing_account_id
  lifecycle {
    prevent_destroy = true
  }
}
# If manage_project_billing=true, import first:
# terraform import 'google_project.billing[0]' k8s-learning-510807
