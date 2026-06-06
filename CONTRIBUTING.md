# Contributing Guidelines

Thank you for contributing to the **Azure VM Hosting Solution**! This guide ensures that the infrastructure remains secure, the configuration is idempotent, and the repository conforms to our engineering standards.

## Branching Strategy

This project follows **Trunk-Based Development (TBD)**:
* `main` – Production-ready code. Direct commits to `main` are prohibited.
* `feature/*` – New features (e.g., `feature/add-ansible-linting`).
* `bugfix/*` – Defect fixes (e.g., `bugfix/mysql-connection-timeout`).
* `hotfix/*` – Critical production fixes.

### Branch Rules
- All changes must be submitted via a Pull Request (PR).
- Keep branches short-lived (typically under 2 days) and focused on a single issue.
- Rebase frequently on `main` to avoid drift.

## Commit Message Convention

This project uses **Conventional Commits**. All commit messages must follow this format:

```text
<type>: <short description>
```

### Allowed Types
- `feat`: New functionality (e.g., `feat: add database backup rotation`).
- `fix`: Bug fixes (e.g., `fix: resolve private link resolution`).
- `docs`: Documentation updates (e.g., `docs: update setup instructions`).
- `refactor`: Internal code improvements without functional changes.
- `test`: Adding or correcting tests.
- `chore`: Maintenance tasks (e.g., dependency updates, path updates).
- `ci`: CI/CD configuration updates.

### Guidelines
- Use present tense (e.g., "add feature", not "added feature").
- Keep the first line under 72 characters.
- Avoid generic messages such as "fix stuff" or "updates".

## Development Workflow

1. **Branch**: Create a short-lived branch from `main` (e.g., `feature/my-new-feature`).
2. **IaC Development**:
   - Work within the `infra/terraform/` directory.
   - Run `terraform validate` and `terraform fmt` to ensure syntax and style.
3. **Configuration Development**:
   - Test Ansible playbooks inside `infra/ansible/`.
   - Ensure all roles are idempotent (running twice changes nothing).
4. **Local Validation**:
   - Run `make infra-init` and verify Spoke backend configuration.
   - Run `make jenkins-sync` to verify hosts inventory generation.

## Testing & Security Checklist

Before opening a Pull Request, verify the following checks:

### 1. Infrastructure (Terraform)
- [ ] No hardcoded secrets or passwords in `.tf` or `.tfvars` files.
- [ ] Network Security Groups (NSG) follow the principle of least privilege.
- [ ] Public IP is only assigned to the Jumpbox VM (no public IPs on Spoke VMs).
- [ ] Resources are tagged with correct environment and owner tags.

### 2. Configuration (Ansible & Jenkins)
- [ ] SSH root login is disabled on all compute hosts.
- [ ] Host firewalls (UFW) are enabled and enforce limits.
- [ ] Secrets are loaded dynamically via Azure Key Vault using VM Managed Identities.

### 3. Verification & Cleanup
- [ ] Backup and recovery scripts execute successfully.
- [ ] `terraform destroy` successfully cleans up all provisioned resources.

## Pull Request Guidelines

Every PR should contain:
- **Summary**: Describe what was implemented.
- **Related Issue**: Reference associated issue numbers (e.g., `Closes #42`).
- **Testing Performed**: Detail unit/integration tests or manual checks.
- Keep PR size under 500 lines of code changes to facilitate prompt reviews.

---
*Maintained by [Chinmay Jog](https://github.com/chinmaymjog).*
