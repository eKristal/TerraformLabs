terraform {
  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }
}

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

resource "null_resource" "web_deploy" {
  
  # ==========================================================================
  # TRIGGER: filemd5() - automaatne redeploy kui fail muutub
  # ==========================================================================
  # filemd5() arvutab faili MD5 räsi (checksum).
  # Kui fail muutub, muutub räsi, trigger muutub, ressurss luuakse uuesti.
  #
  # See on PAREM kui manuaalne version = "1", "2", "3"...
  # sest sa ei pea meeles pidama versiooni muutmist.
  triggers = {
    html_hash = filemd5("${path.module}/files/index.html")
  }

  connection {
    type        = "ssh"
    host        = var.target_host
    user        = var.ssh_user
    private_key = file(pathexpand(var.ssh_private_key))
    timeout     = "2m"
  }

  # ==========================================================================
  # FILE PROVISIONER - kopeeri fail serverisse
  # ==========================================================================
  # source = kohalik fail (WinKlient)
  # destination = asukoht serveris (Ubuntu)
  #
  # MIKS /tmp/? Sest meil pole õigust otse /var/www/html/ kirjutada.
  # Kopeerime /tmp/ ja liigutame siis sudo'ga.
  provisioner "file" {
    source      = "${path.module}/files/index.html"   # Sinu arvutist
    destination = "/tmp/index.html"                    # Serverisse /tmp/
  }

  # ==========================================================================
  # REMOTE-EXEC - liiguta fail õigesse kohta ja käivita Nginx
  # ==========================================================================
  # Provisioner'id käivituvad JÄRJEKORRAS.
  # Kõigepealt file (kopeeri), siis remote-exec (seadista).
  provisioner "remote-exec" {
    inline = [
      # Kontrolli kas Nginx on olemas, paigalda kui pole
      # command -v kontrollib kas käsk eksisteerib
      # &> /dev/null peidab väljundi
      "echo '>>> Kontrollin Nginx olemasolu...'",
      "if ! command -v nginx &> /dev/null; then",
      "  echo '>>> Paigaldan Nginx...'",
      "  sudo apt-get update -qq",
      "  sudo apt-get install -y -qq nginx",
      "fi",

      # Liiguta fail /tmp/ -> /var/www/html/
      # mv on kiirem kui cp + rm
      "echo '>>> Kopeerin veebilehe...'",
      "sudo mv /tmp/index.html /var/www/html/index.html",
      
      # Muuda omanik www-data'ks (Nginx kasutaja)
      "sudo chown www-data:www-data /var/www/html/index.html",

      # Taaskäivita Nginx, et muudatused rakenduks
      "echo '>>> Taaskäivitan Nginx...'",
      "sudo systemctl restart nginx",

      "echo '>>> Valmis!'"
    ]
  }
}

# Outputs
output "web_url" {
  value = "Veebileht: http://${var.target_host}"
}

output "deployed_file_hash" {
  description = "Deploy'tud faili MD5 hash"
  value       = filemd5("${path.module}/.../files/index.html")
}