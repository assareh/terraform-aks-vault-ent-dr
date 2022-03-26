output "resource_group_name" {
  value = azurerm_resource_group.default.name
}

output "primary_kubernetes_cluster_config" {
  value = <<PRIMARY
Run this to configure kubectl:
az aks get-credentials --resource-group ${azurerm_resource_group.default.name} --name ${azurerm_kubernetes_cluster.primary.name}"
PRIMARY
}

output "secondary_kubernetes_cluster_config" {
  value = <<SECONDARY
Run this to configure kubectl:
  value = "az aks get-credentials --resource-group ${azurerm_resource_group.default.name} --name ${azurerm_kubernetes_cluster.secondary.name}"
SECONDARY
}
