provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

# Lookup the Cloudflare zone by name (e.g., example.com)
data "cloudflare_zone" "selected" {
  name = var.cloudflare_zone_name
}

# Create or update an A record pointing to the VM's public IP
resource "cloudflare_record" "vm_a" {
  zone_id         = data.cloudflare_zone.selected.id
  name            = var.cloudflare_record_name
  type            = "A"
  value           = azurerm_public_ip.public_ip.ip_address
  ttl             = var.cloudflare_proxied ? 1 : var.cloudflare_ttl
  proxied         = var.cloudflare_proxied
  allow_overwrite = true
}