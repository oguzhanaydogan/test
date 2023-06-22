variable "name" {
}

variable "resource_group_name" {
}

variable "location" {  
}

variable "service_plan_id" {
}
variable "app_settings" {
    type = map(string)
}

variable "vnet_integration_subnet" {
}

# variable "image_name" {
# }

# variable "image_tag" {
# }