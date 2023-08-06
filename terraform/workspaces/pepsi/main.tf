# local variables

locals {
  rg_name = "pepsi"
  rg_location = "East US"
  sa_name = "pepsisa"
  sa_tier_type = "Standard"
  sa_account_rep_type = "GRS"
  sg_security_protocol = "Tcp"
  sg_security_rule_access = "Allow"
  sg_security_rule_direction = "Inbound"
  sg_security_rule_name = "pepsiSR"
}

# terraform provider 

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.42.0"
    }
  }
   cloud {
    organization = "mrmayanger"
    workspaces {
    name = "pepsi_coke"
    }
   }
  
}

# Configure the Microsoft Azure Provider

provider "azurerm" {
  skip_provider_registration = "true"
  features {}
}

# resourse module

module "resourse_group" {
  source    = "../../../modules/resourse_group"
  base_name = local.rg_name
  location  = local.rg_location
}

# security account

module "security_account" {
  source                      = "../../../modules/security_account"
  sa_base_name                = local.sa_name
  sa_location                 = local.rg_location
  sa_resource_group_name      = module.resourse_group.resourse_group_name
  sa_account_tier             = local.sa_tier_type
  sa_account_replication_type = local.sa_account_rep_type
  depends_on                  = [module.resourse_group]
}

# security group

module "security_group" {
  source                                   = "../../../modules/security_group"
  security_rule_destination_address_prefix = "*"
  security_rule_source_address_prefix      = "*"
  security_rule_destination_port_range     = "*"
  security_rule_source_port_range          = "*"
  security_rule_protocol                   = local.sg_security_protocol
  security_rule_access                     = local.sg_security_rule_access
  security_rule_direction                  = local.sg_security_rule_direction
  security_rule_priority                   = 100
  security_rule_name                       = local.sg_security_rule_name
  sg_resource_group_name                   = module.resourse_group.resourse_group_name
  sg_location                              = local.rg_location
  depends_on                               = [module.resourse_group]
}

# role assignment
  

module "key_vault" {
  source                      = "../../../modules/key_vault"
  keyvault_name               = "kev23q3"
  location                    = local.rg_location
  resource_group_name         = module.resourse_group.resourse_group_name
  name         = "pesiKV1"
  value        = "pepsi_value1"
}

module "container_registry" {
  source                       = "../../../modules/container_registry"
  acr_container_name           = "crmrmayanger"
  acr_resourse_group_name      = module.resourse_group.resourse_group_name
  acr_resourse_group_location  = local.rg_location
  acr_sku                      = "Premium"
  acr_admin_enabled            = false
  acr_georeplication_locations = ["East US", "West Europe"]
}

module "web_app_service_plan" {
  source                              = "../../../modules/web_app_service_plan"
  web_app_service_resource_name       = "mrmayanger"
  web_app_service_location            = local.rg_location
  web_app_service_resource_group_name = module.resourse_group.resourse_group_name
  web_app_service_kind                = "linux"
  web_app_service_reserved            = true
  sku_tier                            = "Standard"
  sku_size                            = "S1"
  depends_on = [ module.container_registry ]
}

module "web_app_service" {
  source                         = "../../../modules/web_app_service"
  web_app_service_name           = "mrmayanger"
  web_app_service_location       = local.rg_location
  acr_ussername                  = module.container_registry.username
  acr_pswd                       = module.container_registry.pwd
  web_app_service_resource_group = module.resourse_group.resourse_group_name
  web_aap_service_plan_id        = module.web_app_service_plan.id
  depends_on                     = [module.web_app_service_plan]
}

module "logic_app"  {
  source = "../../../modules/logic_app"
   location = local.rg_location
   rg_name =  module.resourse_group.resourse_group_name
}