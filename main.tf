#Add Provider Block
terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

provider "aws" {
  region = var.region
}


#Add EC2 Block
#https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance

resource "aws_instance" "guide-tfe-md" {
  ami                    = "ami-0f8ca728008ff5af4"
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.guide-tfe-es-sg.id]
  key_name               = aws_key_pair.ssh_key_pair.key_name

  root_block_device {
    volume_size = "50"
  }

  user_data = templatefile("${path.module}/user-data.sh", {
    region               = var.region
    tfe-pwd              = var.tfe-pwd
    tfe_release_sequence = var.tfe_release_sequence
  })

  provisioner "file" {
    source      = "./license.rli"
    destination = "/tmp/license.rli"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = "${file("./key.pem")}"
      host        = self.public_dns
    }
  }
  tags = {
    Name = var.hostname
  }
  depends_on = [
    aws_key_pair.ssh_key_pair
  ]

}

