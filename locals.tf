locals {

    
  attached_resource_ids = [
    module.acrs["acr_01"].id, 
    module.app_services["app_service_01"].id,
    module.app_services["app_service_02"].id
  ]


  role_assignments = [
    {
      scope = module.acrs["acr_01"].id
      principal_id = module.app_services["app_01"].principal_id
      role_definition = "AcrPull"
    },
    {
      scope = module.acrs["acr_01"].id
      principal_id = module.app_services["app_02"].principal_id
      role_definition = "AcrPull"
    },
    {
      scope = module.acrs["acr_01"].id
      principal_id = module.app_services["app_01"].principal_id
      role_definition = "AcrPull"
    },
    {
      scope = module.acrs["acr_01"].id
      principal_id = module.linux_virtual_machines["linux_virtual_machine_01"].identity[0].principal_id
      role_definition = "AcrPush"
    },
    {
      scope = module.app_services["app_01"].id
      principal_id = module.linux_virtual_machines["linux_virtual_machine_01"].identity[0].principal_id
      role_definition = "Contributor"
    },
    {
      scope = module.app_services["app_02"].id
      principal_id = module.linux_virtual_machines["linux_virtual_machine_01"].identity[0].principal_id
      role_definition = "Contributor"
    }
  ]
}

locals {

}

