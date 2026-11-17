# Contributing

Use this repository to evolve the hardened Azure shared hosting platform while keeping secrets, network topology, and site onboarding predictable.

## Workflow

1. Create a short-lived branch from `main` using `feature/*`, `bugfix/*`, or `hotfix/*`.
2. Keep the branch focused on one layer (Terraform network/compute/storage, Ansible playbook, or documentation) or one clear cross-cutting fix.
3. Use Conventional Commits such as `feat: add site backup rotation` or `docs: update deployment guide`.
4. Run `terraform fmt -check -recursive` and `terraform validate` (see Validation below) before opening a Pull Request.
5. Open a Pull Request with summary, validation performed, and any manual test notes.

## Repo-Specific Guidance

- Terraform lives in `infra/terraform/shared-hub` (management Hub) and `infra/terraform/platform` (spoke). Keep new resources in the layer they belong to - don't reach across the Hub/Spoke boundary except through the documented data-source discovery pattern (tag-based lookups, e.g. `data.azurerm_resources` with `required_tags`).
- Ansible playbooks live in `infra/ansible/playbooks`; keep them idempotent (running twice changes nothing).
- Jenkins job definitions live in `infra/jenkins/jobs` as Jenkins Job DSL/config XML - keep new jobs under the existing `Administrative_Tools` or `Hosting_Management_Portal` folders.
- No hardcoded secrets or passwords in `.tf`, `.tfvars`, or playbook files - secrets flow through Azure Key Vault and local `.env`/`make secrets` only.

## Guardrails

- Do not commit directly to `main`.
- Do not commit real secret values, `.env`, or the `ssh-key` file.
- Public IPs stay on the Jumpbox and Load Balancer only - no public IPs on Spoke web VMs.
- Update README, `HOW_TO_GUIDE.md`, or `SITE_MANAGEMENT.md` when setup, deployment, or site-onboarding steps change.

## Validation

Before opening a Pull Request:

- `terraform fmt -check -recursive` from `infra/terraform/`
- `terraform init -backend=false && terraform validate` for both `infra/terraform/platform` and `infra/terraform/shared-hub`
- a manual deploy/destroy cycle against a real subscription when the change touches Terraform resources, since this repo has no automated cloud test environment
- review the diff for scope and secret safety

## Documentation Updates

- Update README when the deploy flow, Stack Catalog, or onboarding steps change.
- Update `docs/tasks.md` when tracked work starts or finishes.
- Update `docs/architecture.md` when network topology, storage backend, or secret strategy changes.

## AI-Assisted Contributions

AI tools are welcome, with these rules:

- **You are accountable** for every line you submit. Read and understand the code; unreviewed AI output will be closed.
- **Disclose** substantial AI assistance in the PR description.
- Never paste credentials, state files, database dumps or tenant data into AI tools, issues or PRs.
- Low-effort, bulk or off-topic AI-generated PRs and issues may be closed without review.

## Maintainer Automation

The Claude agent GitHub workflow is restricted to the repository owner and has no Azure credentials. Agent-authored PRs get the same review and CI requirements as any other PR and are never auto-merged.

## Security Issues

See [SECURITY.md](SECURITY.md); do not file them as public issues.
