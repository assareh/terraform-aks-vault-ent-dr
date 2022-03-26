resource "random_pet" "prefix" {}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "default" {
  name     = "${random_pet.prefix.id}-rg"
  location = var.location
}

resource "azurerm_kubernetes_cluster" "primary" {
  name                = "${random_pet.prefix.id}-primary"
  location            = azurerm_resource_group.default.location
  resource_group_name = azurerm_resource_group.default.name
  dns_prefix          = "${random_pet.prefix.id}-primary"

  api_server_authorized_ip_ranges = var.allowed_ip_cidrs

  default_node_pool {
    name            = "default"
    node_count      = 3
    vm_size         = "Standard_D2_v2"
    os_disk_size_gb = 30
  }

  identity {
    type = "SystemAssigned"
  }

  role_based_access_control {
    enabled = true
  }
}

resource "azurerm_kubernetes_cluster" "secondary" {
  name                = "${random_pet.prefix.id}-secondary"
  location            = azurerm_resource_group.default.location
  resource_group_name = azurerm_resource_group.default.name
  dns_prefix          = "${random_pet.prefix.id}-secondary"

  api_server_authorized_ip_ranges = var.allowed_ip_cidrs

  default_node_pool {
    name            = "default"
    node_count      = 3
    vm_size         = "Standard_D2_v2"
    os_disk_size_gb = 30
  }

  identity {
    type = "SystemAssigned"
  }

  role_based_access_control {
    enabled = true
  }
}
