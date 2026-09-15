# Architecture

## What This Is

A Hub-Spoke Azure shared hosting platform: a management Hub (Jumpbox +
Key Vault + backups) peered to a Platform Spoke (Front Door, Load
Balancer, web VM fleet, MySQL Flexible Server, website storage). See
the diagram in `README.md`.

## How It Works

1. `make bootstrap` creates the Terraform remote state backend.
2. `make hub-init`/`make hub-deploy` provisions the Hub: Key Vault,
   shared SSH key, backup storage, and the Jumpbox.
3. `make infra-init`/`make infra-deploy` provisions the Spoke: VNet,
   Front Door + WAF, Load Balancer, web VM fleet, MySQL Flexible
   Server, and website storage - peered back to the Hub.
4. `make jenkins-sync`/`make jenkins-up` syncs Ansible playbooks to
   the Jumpbox and starts the Jenkins management portal there.
5. Sites are onboarded through Jenkins jobs (or a direct Ansible CLI
   run), which write Apache/PHP-FPM vhosts and a JSON site record to
   the shared `/backups/sites` registry.

## Key Decisions

- **Decision:** Website storage uses Azure Files Premium NFS instead
  of Azure NetApp Files.
  **Why:** NetApp Files needs a minimum 4 TiB capacity pool and, on
  many subscriptions, a manual quota approval - a real barrier for a
  first try. Azure Files Premium NFS needs neither, at a fraction of
  the cost. The repo's own ADR history already called this out as a
  valid fallback.
  **Revisit if:** Sites need NetApp's sub-millisecond latency at real
  production scale - the `advanced` branch keeps NetApp Files for
  that case.

- **Decision:** `main` deploys a single environment instead of a
  preprod/prod split.
  **Why:** Two full spoke environments double the VM/database/storage
  cost for someone just trying the repo out.
  **Revisit if:** You need a staging environment before promoting
  changes - the `advanced` branch keeps the preprod/prod Terraform
  workspaces for that.
- **Decision:** Jenkins (Dockerized, on the Jumpbox) is the
  administration portal for site onboarding and backups, with a
  documented Ansible CLI fallback.
  **Why:** Centralizes site provisioning, DB dumps, and cert requests
  behind one authenticated UI instead of ad hoc SSH sessions.
  **Revisit if:** The team outgrows a single Jumpbox-hosted Jenkins
  instance.
- **Decision:** All secrets (DB password, SSH private key) live in
  Azure Key Vault, fetched at provision time via the Jumpbox's
  User-Assigned Managed Identity - never stored on disk or in Git.
  **Why:** Zero-trust goal for the platform; a leaked repo or laptop
  should not leak credentials.
  **Revisit if:** Never, without a strong replacement in place first.

## Known Risks / Rough Edges

- This deploys real, billed Azure infrastructure - there is no free
  tier here. Run `make infra-destroy` and `make hub-destroy` when
  you're done experimenting.
- `my_ip` defaults to `"*"` (open SSH ingress to the Jumpbox, though
  key-only auth + Fail2Ban still apply) - set it to your real IP
  before deploying anything you care about.
- The Azure Front Door WAF policy ships in `Detection` mode, not
  `Prevention` - it logs threats but does not block them by default.
- No secret-rotation automation - Key Vault versioning exists, but
  rotating the MySQL admin password still requires a manual
  `terraform apply` with a new `random_password`.
