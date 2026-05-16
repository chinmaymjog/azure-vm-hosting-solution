# Contributing & Testing Guidelines

Thank you for contributing to the **Azure VM Hosting Solution**! This guide ensures that the infrastructure remains secure, the configuration is idempotent, and the solution stays production-ready.

## 🛠️ Development Workflow

1.  **Fork and Clone**: Create a feature branch for your changes.
2.  **IaC Development**:
    *   Test changes in the `infra/` directory.
    *   Run `terraform validate` to ensure syntax correctness.
3.  **Config Development**:
    *   Test Ansible playbooks against a test VM.
    *   Ensure all roles are idempotent (running twice changes nothing).
4.  **Local Validation**:
    *   [ ] Run `make infra-init` and verify the backend is configured.
    *   [ ] Run `make ansible-prep` against a test inventory.

## 🏗️ Adding New Components

When adding new infrastructure modules or playbooks:

1.  **Infrastructure**:
    *   Keep modules modular.
    *   Use variables for all sensitive or environment-specific values.
    *   Ensure all resources are tagged appropriately.
2.  **Ansible**:
    *   Separate logic into clear playbooks (e.g., `server_prep`, `app_deploy`).
    *   Use `ansible-vault` for any sensitive variables if needed.
    *   Ensure handlers are used for service restarts.
3.  **Persistence**:
    *   Document where data is stored (e.g., Azure Managed Disks).
    *   Ensure backup scripts are updated to include new data paths.

## 🧪 Testing Checklist

Before submitting a Pull Request, verify the following:

### 1. Infrastructure (Terraform)
- [ ] No hardcoded secrets in `.tf` files.
- [ ] Network Security Groups (NSG) follow the principle of least privilege.
- [ ] Public IP is only assigned if strictly necessary.

### 2. Configuration (Ansible)
- [ ] SSH root login is disabled during preparation.
- [ ] Firewall (UFW) is enabled with only required ports open.
- [ ] Application stack (WordPress) starts without manual intervention.

### 3. Operational
- [ ] Backup scripts execute successfully and upload to Blob Storage.
- [ ] `terraform destroy` successfully cleans up all resources.

## 📝 Documentation Requirements
- Update `HOW_TO_GUIDE.md` if you change the deployment workflow.
- Ensure any new variables are documented in the `README.md` or as comments in code.

---
*Questions? Reach out to [Chinmay Jog](https://github.com/chinmaymjog).*
