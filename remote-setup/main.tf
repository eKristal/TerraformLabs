terraform {
  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }
}

# Samad muutujad nagu enne
variable "target_host" {
  description = "Ubuntu serveri IP-aadress"
  type        = string
  default     = "10.0.20.20"
}

variable "ssh_user" {
  description = "SSH kasutajanimi"
  type        = string
  default     = "kasutaja"
}

variable "ssh_private_key" {
  description = "SSH privaatvõtme asukoht"
  type        = string
  default     = "~/.ssh/id_ed25519"
}

resource "null_resource" "nginx_setup" {
  
  # ==========================================================================
  # TRIGGERS - Millal käivitub uuesti?
  # ==========================================================================
  # Probleem: provisioner käivitub ainult ressursi LOOMISEL.
  # Kui ressurss on juba olemas, ei käivitu ta uuesti.
  #
  # Lahendus: triggers. Kui trigger'i väärtus muutub,
  # loeb Terraform seda kui "ressurss on muutunud" ja loob uuesti.
  #
  # Muuda "1" -> "2" kui tahad uuesti deploy'da ilma destroy'ta.
  triggers = {
    version = "1"
  }

  connection {
    type        = "ssh"
    host        = var.target_host
    user        = var.ssh_user
    private_key = file(pathexpand(var.ssh_private_key))
    timeout     = "5m"    # Pikem timeout, sest apt install võtab aega
  }

  # ==========================================================================
  # NGINX PAIGALDAMINE JA SEADISTAMINE
  # ==========================================================================
  # Iga käsk käivitub Ubuntu serveris järjest.
  # Kui üks käsk ebaõnnestub (exit code != 0), peatub kogu protsess.
  provisioner "remote-exec" {
    inline = [
      # Samm 1: Uuenda pakettide nimekiri
      # -qq = quiet mode, vähem väljundit
      "echo '>>> Uuendan pakettide nimekirja...'",
      "sudo apt-get update -qq",

      # Samm 2: Paigalda Nginx
      # -y = vastab automaatselt "yes" küsimustele
      "echo '>>> Paigaldan Nginx...'",
      "sudo apt-get install -y -qq nginx",

      # Samm 3: Loo custom veebileht
      # $(hostname) ja $(date) täidetakse serveris
      # tee kirjutab stdin'i faili (sudo õigustega)
      # > /dev/null peidab tee väljundi
      "echo '>>> Loon custom veebilehe...'",
      "echo '<html><body style=\"font-family: Arial; text-align: center; padding: 50px;\"><h1>Deployed by Terraform!</h1><p>Server: '$(hostname)'</p><p>Time: '$(date)'</p></body></html>' | sudo tee /var/www/html/index.html > /dev/null",

      # Samm 4: Käivita ja luba Nginx
      # enable = käivitub automaatselt serveri reboot'il
      # restart = käivita kohe
      "echo '>>> Käivitan Nginx...'",
      "sudo systemctl enable nginx",
      "sudo systemctl restart nginx",

      # Samm 5: Kontrolli, et töötab
      # curl localhost loeb veebilehe sisu
      # grep -o otsib ainult h1 tag'i
      "echo '>>> Kontrollin...'",
      "curl -s http://localhost | grep -o '<h1>.*</h1>'",

      "echo '>>> Valmis!'"
    ]
  }
}

# Outputs näitavad kuidas ligi pääseda
output "web_url" {
  value = "Veebileht: http://${var.target_host}"
}

output "ssh_command" {
  value = "SSH: ssh ${var.ssh_user}@${var.target_host}"
}