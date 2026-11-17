# Security Policy

This repository defines hosting infrastructure (Front Door/WAF, networking,
VMs, a Jenkins jumpbox, databases and backups). Misconfigurations here can
expose real resources and tenant data.

## Reporting a vulnerability

Please **do not open a public issue**. Use GitHub's private reporting:
<https://github.com/chinmaymjog/azure-vm-hosting-solution/security/advisories/new>

Never include subscription or tenant IDs, keys, passwords, state files, database
dumps or real IP addresses in issues or pull requests; use redacted values.

You can expect an initial response within a few days.

## Supported versions

Only the latest `main` receives security fixes.
