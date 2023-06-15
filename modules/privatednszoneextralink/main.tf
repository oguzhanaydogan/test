# Create azure private dns zone virtual network link for acr private endpoint vnet
resource "azurerm_private_dns_zone_virtual_network_link" "private_dns_zone_virtual_network_link" {
  name                  = var.name
  private_dns_zone_name = var.private_dns_zone_name
  resource_group_name   = var.resourcegroup
  virtual_network_id    = var.virtual_network_id
}