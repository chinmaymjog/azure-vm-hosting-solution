# azure-vm-hosting-solution

Terraform + Ansible + Jenkins for a hardened shared-hosting platform on Azure (Hub-Spoke, Front Door/WAF, Ubuntu VMs, Azure Files NFS, MySQL Flexible Server). Layout: `infra/terraform/shared-hub` (management hub, jumpbox), `infra/terraform/platform` (spoke), `infra/ansible`, `infra/jenkins`. A `Makefile` wraps deploy for the human operator. See `CONTRIBUTING.md` for the full conventions.

## Hard rules
- **Never** run `terraform plan/apply/destroy`, `make` deploy targets, `ansible-playbook`, or `az`. You have no cloud credentials; the owner deploys after review.
- Never commit `.env`, the `ssh-key` file, state files, secrets, passwords or real tenant/subscription IDs. Secrets flow through Key Vault and local `.env` only.
- Public IPs stay on the Jumpbox and Load Balancer only; never add public IPs to Spoke web VMs, and don't open SSH to `*`.
- Don't change `.github/workflows/` or backend/state configuration unless the issue asks for it.

## Working on issues
- Verify with `terraform fmt -check -recursive` from `infra/terraform/`, and `terraform init -backend=false && terraform validate` in both `infra/terraform/platform` and `infra/terraform/shared-hub` (same as CI in `.github/workflows/ci.yml`); lint Markdown to the repo's `.markdownlint-cli2.jsonc` rules; for shell changes run `bash -n` and `shellcheck`.
- Keep Ansible playbooks idempotent. Call out any Terraform change that could force replacement of existing resources so the owner can check the real plan.
- Update README, `HOW_TO_GUIDE.md`, `SITE_MANAGEMENT.md` and `docs/` when setup, deployment or onboarding steps change.
- Conventional Commits; keep changes minimal and scoped; one issue per PR.
- Open a PR against `main` that references the issue (`Fixes #N`). Never push to `main` directly.
