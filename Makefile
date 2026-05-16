.PHONY: setup infra-init infra-apply ansible-prep ansible-deploy clean

# Variables
INVENTORY ?= ansible/inventory.ini

help:
	@echo "🛠️ Azure VM Hosting Solution - Makefile"
	@echo ""
	@echo "Usage:"
	@echo "  make infra-init     Initialize Terraform"
	@echo "  make infra-apply    Provision Azure Infrastructure"
	@echo "  make ansible-prep   Harden and prepare the server"
	@echo "  make ansible-deploy Deploy WordPress stack"
	@echo "  make clean          Destroy infrastructure"

infra-init:
	cd infra && terraform init

infra-apply:
	cd infra && terraform apply -auto-approve

ansible-prep:
	cd ansible && ansible-playbook -i ../$(INVENTORY) server_prep_playbook.yml

ansible-deploy:
	cd ansible && ansible-playbook -i ../$(INVENTORY) wordpress.yml

clean:
	cd infra && terraform destroy -auto-approve
