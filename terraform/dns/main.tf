provider "cloudflare" {
  version = "~> 2.0"
  email   = "${var.cloudflare_email}"
  api_key = "${var.cloudflare_api_key}"
}

resource "cloudflare_zone" "main" {
    zone = "lumeo.network"
}

resource "cloudflare_filter" "US_Sanctions" {
  zone_id = cloudflare_zone.main.id
  description = "US Sanctions countries"
  expression = <<EOL
(ip.geoip.country in {"AF" "IR" "KP" "SY" "SD" "VE" "BY" "BI" "CF" "CU" "CG" "CD" "HK" "IQ" "LB" "LY" "ML" "NI" "DO" "SO" "SS" "UA" "RU" "YE" "ZW"})
EOL
}

resource "cloudflare_firewall_rule" "block_us_sanctions" {
  zone_id = cloudflare_zone.main.id
  description = "Block countries based on US Sanctions"
  filter_id = cloudflare_filter.US_Sanctions.id
  action = "block"
}

module "cloudflare_dns_records" {
  source        = "git::https://gitlab.com/geekandi-terraform/cloudflare-dns-record-module.git"
  domain        = cloudflare_zones.main.zone
  zone_id       = cloudflare_zones.main.id
  multi_records =  [
    ["uptime"                , "lumeonetwork.statushub.io", 0, "CNAME", "false"],
    ["@"                     , "mail.@", 10, "MX", "false"],
    ["@"                     , "0 issue \"letsencrypt.org\"", 0, "CAA", "false"],
    ["*"                     , "cname.vercel-dns.com.", 0, "CNAME", "true"],
    ["@"                     , "76.76.21.21", 0, "A", "true"],
  ]
}
