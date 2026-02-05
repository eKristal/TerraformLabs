# =============================================================================
# TERRAFORM SEADED JA PROVIDER
# =============================================================================
# Iga Terraform projekt algab sellega, et ütleme milliseid provider'eid vajame.
# Provider on plugin, mis "räägib" mingi platvormiga - AWS, Azure, või nagu
# meie puhul, kohaliku failisüsteemiga.

terraform {
  required_providers {
    # "local" on provider'i nimi, mida kasutame koodis
    local = {
      source  = "hashicorp/local"  # Kust Terraform selle laeb (Registry)
      version = "~> 2.4"           # ~> tähendab: 2.4, 2.5, 2.9 OK, aga 3.0 mitte
    }
  }
}

# =============================================================================
# RESSURSID - MIDA ME LOOME
# =============================================================================
# resource on Terraform'i põhielement - iga ressurss on üks "asi" mida hallata.
# Süntaks: resource "TÜÜP" "NIMI" { seaded }
#   - TÜÜP: tuleb provider'ist, määrab mida loome (local_file = fail)
#   - NIMI: sina valid, kasutatakse viitamiseks teistes kohtades

# Esimene fail - lihtne tekstifail
resource "local_file" "greeting" {
  # ${path.module} = kaust kus see .tf fail asub
  # Terraform loob "output" kausta automaatselt kui seda pole
  filename = "${path.module}/output/hello.txt"
  
  # Faili sisu - \n tähendab uut rida
  content  = "Tere, SEE ON MUUDETUD Terraform!\nSee fail on loodud IaC-ga.\n"
}

# Teine fail - konfiguratsioonifail
resource "local_file" "config" {
  filename = "${path.module}/output/app.conf"
  
  # <<-EOT on "heredoc" - võimaldab kirjutada mitut rida
  # ilma \n märkideta. Loetavam kui "rida1\nrida2\nrida3"
  # EOT = End Of Text (võid kasutada mis tahes sõna, nt EOF)
  content  = <<-EOT
    server {
      port = 8080
      host = "localhost"
    }
  EOT
}