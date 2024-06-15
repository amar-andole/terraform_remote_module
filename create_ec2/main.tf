data "aws_ami" "ubuntu" {
    most_recent = true
    owners = ["099720109477"]  
}

resource "tls_private_key" "rsa" {
    algorithm = "RSA"
    rsa_bits = 4096
}

resource "aws_key_pair" "deployer" {
    key_name = var.key_name
    public_key = tls_private_key.rsa.public_key_openssh
}

resource "local_file" "pem_key_file" {
    content = tls_private_key.rsa.private_key_openssh
    filename = var.key_path
}

resource "aws_security_group" "allow_ssh" {
    name = var.sg_name  
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh_ipv4" {
    security_group_id = aws_security_group.allow_ssh.id
    cidr_ipv4 = "0.0.0.0/0"
    from_port = 22
    ip_protocol = "tcp"
    to_port = 22
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
    security_group_id = aws_security_group.allow_ssh.id
    cidr_ipv4 = "0.0.0.0/0"
    ip_protocol = "-1"
}

resource "aws_instance" "create_ec2" {
    ami = data.aws_ami.ubuntu.id
    instance_type = var.instance_type
    key_name = aws_key_pair.deployer.key_name
    vpc_security_group_ids = [aws_security_group.allow_ssh.id]

    tags = {
        Name = "Terraform-ec2"
    }  
}

