# Architecture

## What This Is

A Hub-Spoke Azure shared hosting platform: a management Hub (Jumpbox +
Key Vault + backups) peered to a Platform Spoke (Front Door, Load
Balancer, web VM fleet, MySQL Flexible Server, Azure NetApp Files),
deployable as separate preprod and prod environments. See the diagram
in `README.md`.

## How It Works

1. `make bootstrap` creates the Terraform remote state backend.
2. `make hub-init`/`make hub-deploy` provisions the Hub: Key Vault,
   shared SSH key, backup storage, and the Jumpbox.
3. `make infra-init` then `make infra-preprod` / `make infra-prod`
   provisions a Spoke: VNet, Front Door + WAF, Load Balancer, web VM
   fleet, MySQL Flexible Server, and Azure NetApp Files - peered back
   to the Hub. Each environment is its own Terraform workspace.
4. `make jenkins-sync`/`make jenkins-up` syncs Ansible playbooks to
   the Jumpbox and starts the Jenkins management portal there.
5. Sites are onboarded through Jenkins jobs (or a direct Ansible CLI
   run), which write Apache/PHP-FPM vhosts and a JSON site record to
   the shared `/backups/sites` registry.

## Key Decisions

- **Decision:** Hub-Spoke network topology - the Hub holds
  administrative nodes (Jumpbox, Vault, backups share); Spokes hold
  web VMs and databases; communication is peering-only.
  **Why:** Management traffic and backups need to stay separate from
  web traffic.
  **Revisit if:** A single flat VNet becomes preferable for a
  much smaller deployment - see the `main` branch, which still keeps
  Hub-Spoke but drops the preprod/prod split.
- **Decision:** Azure NetApp Files (`/netappwebsites`) for shared
  website storage, mounted via NFS v4.1.
  **Why:** Compute nodes need concurrent, low-latency, high-throughput
  access to the same web directories - NetApp's sub-millisecond
  latency beats plain Azure Files NFS for live site requests.
  **Revisit if:** The 4 TiB minimum capacity pool and quota approval
  are a bigger barrier than the latency is worth - the `main` branch
  swaps this for Azure Files Premium NFS by default.
- **Decision:** Separate preprod and prod Terraform workspaces sharing
  one Hub.
  **Why:** Staged rollouts need an isolated environment to validate
  changes before they hit production traffic.
  **Revisit if:** You only ever need one environment - `main` deploys
  a single environment instead, at lower first-deploy cost.
- **Decision:** All secrets (DB password, SSH private key) live in
  Azure Key Vault, fetched at provision time via the Jumpbox's
  User-Assigned Managed Identity - never stored on disk or in Git.
  **Why:** Zero-trust goal for the platform; a leaked repo or laptop
  should not leak credentials.
  **Revisit if:** Never, without a strong replacement in place first.

## Known Risks / Rough Edges

- This deploys real, billed Azure infrastructure at enterprise scale -
  NetApp Files alone has a real minimum monthly cost even idle. Run
  `make infra-destroy ENV=preprod` / `ENV=prod` and `make hub-destroy`
  when you're done experimenting.
- `my_ip` defaults to `"*"` (open SSH ingress to the Jumpbox, though
  key-only auth + Fail2Ban still apply) - set it to your real IP
  before deploying anything you care about.
- The Azure Front Door WAF policy ships in `Detection` mode, not
  `Prevention` - it logs threats but does not block them by default.
- No secret-rotation automation - Key Vault versioning exists, but
  rotating the MySQL admin password still requires a manual
  `terraform apply` with a new `random_password`.
