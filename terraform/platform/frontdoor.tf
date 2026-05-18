resource "azurerm_cdn_frontdoor_profile" "afd" {
  name                = "afd-shared-${var.environment}"
  resource_group_name = azurerm_resource_group.rg.name
  sku_name            = var.afd_sku
  tags                = var.tags
}

resource "azurerm_cdn_frontdoor_endpoint" "endpoint" {
  name                     = "shared-hosting-${var.environment}"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.afd.id
}

resource "azurerm_cdn_frontdoor_origin_group" "origin_group" {
  name                     = "lb-origin-group"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.afd.id
  session_affinity_enabled = false

  health_probe {
    interval_in_seconds = 240
    path                = "/"
    protocol            = "Http"
    request_type        = "HEAD"
  }

  load_balancing {
    additional_latency_in_milliseconds = 0
    sample_size                        = 4
    successful_samples_required        = 2
  }
}

resource "azurerm_cdn_frontdoor_origin" "origin" {
  name                          = "lb-origin"
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.origin_group.id
  enabled                       = true

  certificate_name_check_enabled = false
  host_name                      = azurerm_public_ip.lb_pip.ip_address
  http_port                      = 80
  https_port                     = 443
  priority                       = 1
  weight                         = 1000
}

resource "azurerm_cdn_frontdoor_route" "route" {
  name                          = "default-route"
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.endpoint.id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.origin_group.id
  cdn_frontdoor_origin_ids       = [azurerm_cdn_frontdoor_origin.origin.id]

  supported_protocols    = ["Http", "Https"]
  patterns_to_match      = ["/*"]
  forwarding_protocol    = "HttpOnly"
  link_to_default_domain = true
}

output "frontdoor_url" {
  value = azurerm_cdn_frontdoor_endpoint.endpoint.host_name
}

resource "azurerm_cdn_frontdoor_firewall_policy" "waf" {
  name                              = "wafshared${var.environment}"
  resource_group_name               = azurerm_resource_group.rg.name
  sku_name                          = var.afd_sku
  enabled                           = true
  mode                              = "Detection"
  
  # Note: managed_rule blocks require Premium_AzureFrontDoor SKU.
  # If using Standard SKU, only custom rules are supported.
  
  tags = var.tags
}

resource "azurerm_cdn_frontdoor_security_policy" "waf_assoc" {
  name                     = "WAF-Association"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.afd.id

  security_policies {
    firewall {
      cdn_frontdoor_firewall_policy_id = azurerm_cdn_frontdoor_firewall_policy.waf.id
      association {
        domain {
          cdn_frontdoor_domain_id = azurerm_cdn_frontdoor_endpoint.endpoint.id
        }
        patterns_to_match = ["/*"]
      }
    }
  }
}
