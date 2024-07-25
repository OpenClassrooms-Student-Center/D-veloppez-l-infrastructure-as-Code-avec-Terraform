terraform {
  # Définition des providers utilisés par le déploiement
  # avec la version souhaité
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  # Définition de la version de Terraform requise
  required_version = ">= 1.2.0"
}

# Configuration du provider "aws"
# Voir https://registry.terraform.io/providers/hashicorp/aws/latest/docs
# pour plus de détails
provider "aws" {
  # Définition de la "région" ciblée par le déploiement
  # Voir https://aws.amazon.com/fr/about-aws/global-infrastructure/
  region = "us-east-1"
}

# Définit d'une ressource de type
# "aws_instance" permettant de créer un serveur
# sur l'infrastructure Amazon EC2
resource "aws_instance" "my_server" {
  # Définition de l'AMI (identifiant du modèle d'image disque)
  # et du type d'instance (i.e. caractéristiques de performance)
  # de la machine virtuelle à créer
  ami           = "ami-04a81a99f5ec58529"
  instance_type = "t2.micro"

  # Définition des étiquettes à associer à la machine
  # virtuelle, ici "Name" pour définir un nom
  tags = {
    Name = "OpenClassrooms-P6"
  }

  # Optionnel - Définition des éléments permettant une connexion SSH
  # sur la machine déployée
  vpc_security_group_ids = ["${aws_security_group.my_security_group.id}"]
  key_name               = aws_key_pair.generated_key.key_name
}

// La suite de la configuration permet de configurer un accès SSH
// sur la machine AWS. 
// Cette section n'est pas demandée pour l'exercice 1 car
// un peu technique mais sera nécessaire pour l'exercice 2.

resource "aws_security_group" "my_security_group" {
  name = "allow-ssh"
  ingress {
    cidr_blocks = [
      "0.0.0.0/0"
    ]
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

variable "generated_key_name" {
  type        = string
  default     = "openclassrooms_devops_p6"
  description = "Key-pair generated by Terraform"
}

// On créait une nouvelle paire de clés SSH
// afin que celle ci soit utilisable pour se connecter
// à notre serveur
resource "tls_private_key" "my_ssh_key" {
  algorithm = "ED25519"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated_key" {
  key_name   = var.generated_key_name
  public_key = tls_private_key.my_ssh_key.public_key_openssh
}

// On stocke notre clé SSH privée localement dans le répertoire
// ~/.ssh.
resource "local_sensitive_file" "pem_file" {
  filename             = pathexpand("~/.ssh/aws_${aws_key_pair.generated_key.key_name}.pem")
  file_permission      = "600"
  directory_permission = "700"
  content              = tls_private_key.my_ssh_key.private_key_pem
}
