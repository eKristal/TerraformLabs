# =============================================================================
# PROVIDER: NULL
# =============================================================================
# "null" provider on eriline - ta ei loo midagi päriselt.
# Tema ainus eesmärk on pakkuda "null_resource" ressurssi,
# mis on konteiner provisioner'itele.
# Päris elus kasutaksid aws_instance, azurerm_virtual_machine jne.

terraform {
  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }
}

# =============================================================================
# MUUTUJAD SSH ÜHENDUSEKS
# =============================================================================
# Paneme SSH andmed muutujatesse, et oleks lihtne muuta
# (näiteks kui tahad testida teise serveriga)

variable "target_host" {
  description = "Ubuntu serveri IP-aadress"
  type        = string
  default     = "10.0.20.20"    # Ubuntu-1 IP sinu labori võrgus
}

variable "ssh_user" {
  description = "SSH kasutajanimi"
  type        = string
  default     = "kasutaja"       # Muuda kui sinu kasutaja on teine
}

variable "ssh_private_key" {
  description = "SSH privaatvõtme asukoht"
  type        = string
  default     = "~/.ssh/id_ed25519"  # Windowsis: C:\Users\SINU_NIMI\.ssh\id_ed25519
}

# =============================================================================
# NULL RESOURCE + PROVISIONER
# =============================================================================
# null_resource ei loo midagi - ta on lihtsalt "konteiner" provisioner'itele.
# Provisioner on kood, mis käivitub ressursi loomisel.

resource "null_resource" "system_info" {
  
  # CONNECTION: Kuidas Terraform serveriga ühendub
  # -------------------------------------------------
  # See plokk ütleb Terraformile SSH ühenduse parameetrid.
  # Ilma selleta ei tea Terraform, kuhu ühenduda.
  connection {
    type        = "ssh"                                      # SSH (Linux) või WinRM (Windows)
    host        = var.target_host                            # IP-aadress
    user        = var.ssh_user                               # Kasutajanimi
    private_key = file(pathexpand(var.ssh_private_key))      # SSH võtme SISU (mitte tee!)
    timeout     = "2m"                                       # Kui kaua oodata ühendust
  }
  # MIKS pathexpand()? Windows'is ei tööta ~ alati.
  # pathexpand("~/.ssh/id") -> "C:/Users/kasutaja/.ssh/id"
  #
  # MIKS file()? Connection tahab võtme SISU, mitte failiteed.
  # file() loeb faili ja tagastab selle sisu stringina.

  # REMOTE-EXEC: Käsud, mis käivitatakse serveris
  # -------------------------------------------------
  # inline = nimekiri käskudest, käivitatakse järjest
  provisioner "remote-exec" {
    inline = [
      # Iga string on üks käsk, mis käivitub Ubuntu serveris
      "echo '=== System Info ==='",
      "hostname",                              # Serveri nimi
      "whoami",                                # Praegune kasutaja
      "uname -a",                              # Kerneli info
      "echo ''",
      "echo '=== Network ==='",
      "ip -4 addr show | grep 'inet ' | head -2",  # IP-aadressid
      "echo ''",
      "echo '=== Disk ==='",
      "df -h / | tail -1",                     # Kettakasutus
      "echo ''",
      "echo '=== Done ==='"
    ]
  }
}

# Output kinnitab, et kõik õnnestus
output "status" {
  value = "SSH ühendus serveriga ${var.target_host} õnnestus!"
}