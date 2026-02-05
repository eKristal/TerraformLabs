# Provider jääb samaks nagu enne
terraform {
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4"
    }
  }
}

# =============================================================================
# RESSURSID MUUTUJATEGA
# =============================================================================
# Nüüd kasutame var.xxx muutujaid hardcoded väärtuste asemel.
# ${var.nimi} - kui muutuja on stringi sees
# var.nimi - kui muutuja on eraldi väärtus

resource "local_file" "greeting" {
  filename = "${path.module}/output/hello.txt"
  
  # Muutujad stringi sees - kasuta ${var.xxx} süntaksit
  content  = <<-EOT
    Tere tulemast ${var.app_name} rakendusse!
    Keskkond: ${var.environment}
    Port: ${var.port}
  EOT
}

resource "local_file" "config" {
  # Failinimi sisaldab nüüd rakenduse nime JA keskkonda
  # dev: myapp-dev.conf, prod: myapp-prod.conf
  # Nii saad hoida erinevaid keskkondi koos ilma konfliktita
  filename = "${path.module}/output/${var.app_name}-${var.environment}.conf"
  
  content  = <<-EOT
    # ${var.app_name} Configuration
    # Environment: ${var.environment}
    # Genereeritud Terraformiga

    server {
      port = ${var.port}
      host = "localhost"
      env  = "${var.environment}"
    }
  EOT
}