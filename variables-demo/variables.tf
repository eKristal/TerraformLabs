# =============================================================================
# SISENDMUUTUJAD (Input Variables)
# =============================================================================
# Muutujad teevad konfiguratsiooni taaskasutatavaks.
# Sama kood töötab dev, test ja prod keskkonnas - muudad ainult muutujaid.

# Keskkonna muutuja - määrab kas dev, test või prod
variable "environment" {
  description = "Keskkonna nimi (dev/test/prod)"  # Dokumentatsioon teistele
  type        = string                             # Andmetüüp: string, number, bool, list, map
  default     = "dev"                              # Vaikeväärtus kui kasutaja ei anna

  # Validation tagab, et keegi ei pane "banana" keskkkonnaks
  validation {
    condition     = contains(["dev", "test", "prod"], var.environment)
    error_message = "Environment peab olema: dev, test või prod."
  }
}

# Rakenduse nimi - kasutatakse failinimedes
variable "app_name" {
  description = "Rakenduse nimi"
  type        = string
  default     = "myapp"
}

# Port number - näitab kuidas number tüüp töötab
variable "port" {
  description = "Rakenduse port"
  type        = number    # number, mitte string! Terraform kontrollib tüüpi
  default     = 8080

  # Kontrollime, et port oleks mõistlikus vahemikus
  # && on "ja" operaator - mõlemad tingimused peavad olema tõesed
  validation {
    condition     = var.port > 1024 && var.port < 65535
    error_message = "Port peab olema vahemikus 1025-65534."
  }
}