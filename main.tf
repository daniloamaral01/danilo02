data "aws_ami" "slacko-app"{
    most_recent = true
    owners = ["amazon"]

    filter {
        name = "name"
        values = ["Amazon*"]
    }

    filter {
        name = "architecture"
        values = ["x86_64"]
    }
}

data "aws_subnet" "subnet_public" {
    cidr_block = "10.0.102.0/24"
}

# SSH Key
resource "aws_key_pair" "slacko-sshkey" {
    key_name = "slacko-app-key"
    public_key = "YOUR_SSH_PUBLIC_KEY"
  
}

resource "aws_instance" "slacko-app" {
    ami = data.aws_ami.slacko-app.id
    instance_type = "t2.micro"
    subnet_id = data.aws_subnet.subnet_public.id
    associate_public_ip_address = true

    tags = {
      "Name" = "slacko-app"
    }
    key_name = aws_key_pair.slacko-sshkey.id
    # bootstrap file
    user_data = file("ec2.sh")
}

resource "aws_instance" "mongodb" {
    ami = data.aws_ami.slacko-app.id
    instance_type = "t2.micro"
    subnet_id = data.aws_subnet.subnet_public.id

    tags = {
      "Name" = "mongodb"
    }
    key_name = aws_key_pair.slacko-sshkey.id
    user_data = file("mongodb.sh")
}

resource "aws_security_group" "allow-slacko" {
    name = "allow_ssh_http"
    description = "allow ssh and http port"
    vpc_id = "vpc-0fbc65bdb28267cd0"
    

    tags = {
      "Name" = "allow_ssh_http"
    }
}

resource "aws_security_group_rule" "allow-slacko-ingress-http" {
    type = "ingress"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

    security_group_id = aws_security_group.allow-slacko.id
}

resource "aws_security_group_rule" "allow-slacko-ingress-ssh" {
    type = "ingress"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

    security_group_id = aws_security_group.allow-slacko.id
}

resource "aws_security_group_rule" "allow-slacko-egress-all" {
    type = "egress"
    from_port = 0
    to_port = 0
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

    security_group_id = aws_security_group.allow-slacko.id
}



resource "aws_security_group" "allow-mongodb" {
    name = "allow_mongodb"
    description = "allow nmongodb"
    vpc_id = "vpc-0fbc65bdb28267cd0"

    tags = {
      "Name" = "allow_mongodb"
    }
}



resource "aws_security_group_rule" "allow-mongo-ingress-mongo" {
    type = "ingress"
    from_port = 27017
    to_port = 27017
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

    security_group_id = aws_security_group.allow-mongodb.id
  
}

resource "aws_security_group_rule" "allow-mongo-egress-all" {
    type = "egress"
    from_port = 0
    to_port = 0
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

    security_group_id = aws_security_group.allow-mongodb.id
  
}

resource "aws_network_interface_sg_attachment" "mongodb-sg" {
    security_group_id = aws_security_group.allow-mongodb.id
    network_interface_id = aws_instance.mongodb.primary_network_interface_id
}

resource "aws_network_interface_sg_attachment" "slacko" {
    security_group_id = aws_security_group.allow-slacko.id
    network_interface_id = aws_instance.slacko-app.primary_network_interface_id
}

resource "aws_route53_zone" "slacko_zone" {
    name = "iaac0506.com.br"
    vpc {
        vpc_id = "vpc-0fbc65bdb28267cd0" 
    }
}

resource "aws_route53_record" "mongodb" {
    zone_id = aws_route53_zone.slacko_zone.id
    name = "mongodb.iaac0506.com.br"
    type = "A"
    ttl = "300"
    records = [aws_instance.mongodb.private_ip]
}
