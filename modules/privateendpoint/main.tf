
# Create azure private endpoint
resource "azurerm_private_endpoint" "private_endpoint" {
  name                = "${var.attached_resource_name}-private-endpoint"
  resource_group_name = var.resourcegroup
  location            = var.location
  subnet_id           = var.subnet_id
  
  
  private_service_connection {
    name                           = "${var.attached_resource_name}-service-connection"
    private_connection_resource_id = var.attached_resource_id
    is_manual_connection           = false
    subresource_names = [
      var.subresource_name
    ]
  }
  
  private_dns_zone_group {
    name = "${var.attached_resource_name}-private-dns-zone-group"
    private_dns_zone_ids = var.private_dns_zone_ids
  }
}