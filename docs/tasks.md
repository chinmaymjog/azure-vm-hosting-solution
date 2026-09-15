# Tasks

Keep this short and current. Delete finished work you don't need a
record of - this is a working list, not an audit log.

## Now

- [ ] ...

## Next

- [ ] Switch the Front Door WAF policy from `Detection` to
      `Prevention` mode once traffic patterns are known.
- [ ] Add a secret-rotation runbook for the MySQL admin password.

## Done

- [x] Ported the LB backend-pool, MySQL TLS, and provider-version-pin
      fixes from `main`, and de-bloated the doc format to match - full
      NetApp Files + preprod/prod feature set unchanged (2026-09-15)
- [x] Fixed the Load Balancer backend pool association hardcoding
      `count = 2` instead of `var.vm_count`, silently dropping VMs
      from traffic when `vm_count != 2` (2026-09-15)
- [x] Removed the `require_secure_transport = OFF` MySQL Flexible
      Server override that contradicted the platform's zero-trust
      goal (2026-09-15)
- [x] Pinned the `azurerm` provider to `~> 4.0` - the previously
      unbounded `>= 4.0` constraint pulled provider v5.x on a fresh
      `terraform init`, which has breaking schema changes and broke
      `terraform validate` entirely (2026-09-15)
