# Generate the SSH key pair
resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Upload the public key to AWS
resource "aws_key_pair" "ssh_key_pair" {
  key_name   = "key"
  public_key = tls_private_key.ssh_key.public_key_openssh
}

resource "local_file" "foo" {
  content         = tls_private_key.ssh_key.private_key_pem
  filename        = "key.pem"
  file_permission = "0400"
}


output "ssh_public_ip" {
  description = "Command for ssh to the Client public IP of the EC2 Instance"
  value = [
    "ssh ubuntu@${aws_eip.bar.public_dns} -i key.pem"
  ]
}


output "replicated-ui" {
  value = "https://${aws_eip.bar.public_dns}:8800/"
}