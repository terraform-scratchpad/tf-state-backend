#
# Terraform template creates storage account and container serving as backend for
# all QAs configurations
#
provider "azurerm" {
  version = "1.12.0"
}

variable tf_state_resource_group_name {
  type = "string"
  default = "QA-DIOR-TF-STATE"
}

variable "tags" {
  type = "map"
  default = {
    scope         = "qa"
    source        = "terraform"
    env           = "staging"
    costEntity    = "dior"
  }
}

resource "azurerm_resource_group" "tf-state-rg" {
  location                  = "${var.location}"
  name                      = "${var.tf_state_resource_group_name}"
  tags                      = "${var.tags}"
}

resource "azurerm_storage_account" "tf-state-storage-account" {
  account_replication_type  = "LRS"
  account_tier              = "Standard"
  location                  = "${var.location}"
  name                      = "qatfstate"
  resource_group_name       = "${azurerm_resource_group.tf-state-rg.name}"
  tags                      = "${var.tags}"
}

resource "azurerm_storage_container" "tf-state-container" {
  name                      = "qatfstatecnt"
  resource_group_name       = "${azurerm_resource_group.tf-state-rg.name}"
  storage_account_name      = "${azurerm_storage_account.tf-state-storage-account.name}"
}

resource "null_resource" "set-access-key" {
  provisioner "local-exec" {
    command = <<EOT
echo "ARM_ACCESS_KEY=${azurerm_storage_account.tf-state-storage-account.primary_access_key}" > /usr/local/var/azure-terraform-access_key.sh
source /usr/local/var/azure-terraform-access_key.sh
echo "env var ARM_ACCESS_KEY has been set locally"
    EOT
  }
}