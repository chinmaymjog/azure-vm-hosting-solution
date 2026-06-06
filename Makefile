-include .env

.PHONY: help setup bootstrap hub-init hub-deploy infra-init infra-preprod infra-prod clean

# --- 🏷️ Configuration ---
PROJECT_NAME_INPUT ?= $(PROJECT_NAME)
ifeq ($(PROJECT_NAME_INPUT),)
  PROJECT_NAME_INPUT = shrdhosting
endif

# Sanitise PROJECT_NAME: lowercase, remove all non-alphanumeric characters (spaces, special chars, hyphens), max 16 chars
PROJECT_NAME := $(shell echo "$(PROJECT_NAME_INPUT)" | tr 'A-Z' 'a-z' | tr -dc 'a-z0-9' | cut -c1-16)

# Storage account name for state (must be unique, loaded from .env if generated)
TF_STATE_STORAGE ?= st$(PROJECT_NAME)tfstate
# Resource group for state (loaded from .env if generated)
TF_STATE_RG ?= rg-$(PROJECT_NAME)-state

help:
	@echo "🛠️ Azure Shared Hosting Platform - Makefile"
	@echo ""
	@echo "Project: $(PROJECT_NAME)"
	@echo "State Storage RG: $(TF_STATE_RG)"
	@echo "State Storage Account: $(TF_STATE_STORAGE)"
	@echo ""
	@echo "Usage:"
	@echo "  make setup          Initialize unique prefix for Azure (.env)"
	@echo "  make bootstrap      Bootstrap Azure state storage (RG & SA)"
	@echo "  make hub-init       Initialize Shared Hub"
	@echo "  make hub-deploy     Deploy Shared Hub"
	@echo "  make infra-init     Initialize Platform Spokes"
	@echo "  make infra-preprod  Deploy Preprod Environment"
	@echo "  make infra-prod     Deploy Prod Environment"
	@echo "  make jenkins-sync   Sync Automation Stack (Ansible + Jenkins)"
	@echo "  make jenkins-up     Spin up Jenkins Management Portal"

setup:
	@if [ ! -f .env ] || [ "$(origin PROJECT_NAME_INPUT)" = "environment" ] || [ "$(origin PROJECT_NAME_INPUT)" = "command line" ]; then \
		CLEAN_PROJECT_NAME=$$(echo "$(PROJECT_NAME_INPUT)" | tr 'A-Z' 'a-z' | tr -dc 'a-z0-9' | cut -c1-16); \
		RAND_SUFFIX=$$(LC_ALL=C tr -dc 'a-z0-9' < /dev/urandom | head -c 6); \
		echo "PROJECT_NAME=$$CLEAN_PROJECT_NAME" > .env; \
		echo "TF_STATE_STORAGE=st$${CLEAN_PROJECT_NAME}$$RAND_SUFFIX" >> .env; \
		echo "TF_STATE_RG=rg-$${CLEAN_PROJECT_NAME}-state" >> .env; \
		echo "TF_STATE_CONTAINER=tfstate" >> .env; \
		echo "✅ Created/Updated .env with:"; \
		echo "   PROJECT_NAME=$$CLEAN_PROJECT_NAME"; \
		echo "   TF_STATE_RG=rg-$${CLEAN_PROJECT_NAME}-state"; \
		echo "   TF_STATE_STORAGE=st$${CLEAN_PROJECT_NAME}$$RAND_SUFFIX"; \
		echo "   TF_STATE_CONTAINER=tfstate"; \
	else \
		echo "✅ .env already exists:"; \
		cat .env; \
	fi

bootstrap:
	@echo "🚀 Idempotent Bootstrapping of Azure State Storage..."
	@if ! az group show --name rg-$(PROJECT_NAME)-state >/dev/null 2>&1; then \
		echo "Creating Resource Group: rg-$(PROJECT_NAME)-state..."; \
		az group create --name rg-$(PROJECT_NAME)-state --location westeurope --only-show-errors > /dev/null; \
	else \
		echo "✅ Resource Group rg-$(PROJECT_NAME)-state already exists."; \
	fi
	@if ! az storage account show --name $(TF_STATE_STORAGE) --resource-group rg-$(PROJECT_NAME)-state >/dev/null 2>&1; then \
		echo "Creating Storage Account: $(TF_STATE_STORAGE)..."; \
		az storage account create --name $(TF_STATE_STORAGE) --resource-group rg-$(PROJECT_NAME)-state --sku Standard_LRS --encryption-services blob --min-tls-version TLS1_2 --only-show-errors > /dev/null; \
	else \
		echo "✅ Storage Account $(TF_STATE_STORAGE) already exists."; \
	fi
	@CONNECTION_STRING=$$(az storage account show-connection-string --name $(TF_STATE_STORAGE) --resource-group rg-$(PROJECT_NAME)-state --query connectionString -o tsv 2>/dev/null); \
	if [ -n "$$CONNECTION_STRING" ]; then \
		if ! az storage container show --name tfstate --connection-string "$$CONNECTION_STRING" >/dev/null 2>&1; then \
			echo "Creating Blob Container: tfstate..."; \
			az storage container create --name tfstate --connection-string "$$CONNECTION_STRING" --only-show-errors >/dev/null; \
		else \
			echo "✅ Blob Container tfstate already exists."; \
		fi; \
	else \
		echo "❌ Error: Could not retrieve Storage Account connection string."; \
		exit 1; \
	fi
	@echo "🎉 State storage bootstrap complete!"

# --- Shared Hub ---
hub-init:
	cd infra/terraform/shared-hub && terraform init \
		-backend-config="resource_group_name=$(TF_STATE_RG)" \
		-backend-config="storage_account_name=$(TF_STATE_STORAGE)"

hub-deploy:
	cd infra/terraform/shared-hub && terraform apply \
		-var="project_name=$(PROJECT_NAME)" \
		-auto-approve

# --- Environment Spokes ---
infra-init:
	cd infra/terraform/platform && terraform init \
		-backend-config="resource_group_name=$(TF_STATE_RG)" \
		-backend-config="storage_account_name=$(TF_STATE_STORAGE)"

infra-preprod:
	cd infra/terraform/platform && terraform workspace select preprod || terraform workspace new preprod
	cd infra/terraform/platform && terraform apply \
		-var-file="environments/preprod.tfvars" \
		-var="project_name=$(PROJECT_NAME)" \
		-auto-approve

infra-prod:
	cd infra/terraform/platform && terraform workspace select prod || terraform workspace new prod
	cd infra/terraform/platform && terraform apply \
		-var-file="environments/prod.tfvars" \
		-var="project_name=$(PROJECT_NAME)" \
		-auto-approve

# --- 🏗️ Configuration & Onboarding ---

# Sync Jenkins and Ansible logic for all environments
jenkins-sync:
	@echo "📡 Generating Dynamic Inventory for All Environments..."
	@echo "[local]\nlocalhost ansible_connection=local\n" > infra/ansible/hosts
	@for env in preprod prod; do \
		if [ "$$env" = "preprod" ]; then group="preproduction"; else group="production"; fi; \
		echo "Fetching IPs for $$env..."; \
		WEB_IPS=$$(cd infra/terraform/platform && terraform workspace select $$env >/dev/null 2>&1 && terraform output -json vm_private_ips | jq -r '.[]' 2>/dev/null || echo ""); \
		echo "[$$group]" >> infra/ansible/hosts; \
		count=1; \
		for ip in $$WEB_IPS; do \
			echo "webvm-ubu-shrd01-$$env-we-0$$count ansible_host=$$ip" >> infra/ansible/hosts; \
			count=$$((count+1)); \
		done; \
		echo "" >> infra/ansible/hosts; \
	done
	@echo "[all:vars]\nansible_user=azureuser" >> infra/ansible/hosts
	@echo "📡 Syncing Automation Stack to Jumpbox..."
	@rsync -avz -e "ssh -o StrictHostKeyChecking=no -i ./ssh-key" --exclude=".DS_Store" ./infra/ azureuser@$$(cd infra/terraform/shared-hub && terraform output -raw ssh_command_jumpbox | awk '{print $$NF}' | cut -d@ -f2):~/infra/

# Spin up Jenkins on the Jumpbox with Secure Credential Injection
jenkins-up:
	@SSH_KEY=$$(cat ssh-key); \
	JUMPBOX_IP=$$(cd infra/terraform/shared-hub && terraform output -raw ssh_command_jumpbox | awk '{print $$NF}' | cut -d@ -f2); \
	echo "🚀 Spinning up Jenkins on the Jumpbox ($$JUMPBOX_IP)..."; \
	ssh -o StrictHostKeyChecking=no -i ./ssh-key -A azureuser@$$JUMPBOX_IP \
		"export SSH_PRIVATE_KEY=\"$$SSH_KEY\" && cd ~/infra/jenkins && docker compose up --build -d" && \
	echo "" && \
	echo "========================================================================" && \
	echo "🔒 SECURE PORTAL ACCESS (Jenkins UI is fully hardened & shielded)" && \
	echo "========================================================================" && \
	echo "Step 1: Open a secure SSH tunnel in a new terminal window:" && \
	echo "        ssh -L 8080:localhost:8080 -i ./ssh-key azureuser@$$JUMPBOX_IP" && \
	echo "" && \
	echo "Step 2: Access the Hosting Management Portal in your browser:" && \
	echo "        👉 http://localhost:8080" && \
	echo "" && \
	echo "Step 3: Log in using the default portal credentials:" && \
	echo "        👤 Username: admin" && \
	echo "        🔑 Password: SecureAdminPassword2026!" && \
	echo "========================================================================" && \
	echo ""

# Destroy infrastructure for a specific environment
infra-destroy:
	@if [ -z "$(ENV)" ]; then echo "❌ Error: Please specify ENV=preprod or ENV=prod"; exit 1; fi
	cd infra/terraform/platform && terraform workspace select $(ENV) || terraform workspace new $(ENV)
	cd infra/terraform/platform && terraform destroy -var-file="environments/$(ENV).tfvars" -var="project_name=$(PROJECT_NAME)" -auto-approve

# Destroy the Hub (Run this LAST)
hub-destroy:
	cd infra/terraform/shared-hub && terraform destroy -var="project_name=$(PROJECT_NAME)" -auto-approve

clean:
	@echo "Cleanup targets: 'make infra-destroy ENV=...' or 'make hub-destroy'"
