resource "aws_vpc" "test-vpc" {
  cidr_block           = "10.123.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "dev"
  }
}

resource "aws_subnet" "test-subnet" {
  vpc_id                  = aws_vpc.test-vpc.id
  cidr_block              = "10.123.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"

  tags = {
    Name = "dev-public"
  }
}

resource "aws_internet_gateway" "test-internet_gateway" {
  vpc_id = aws_vpc.test-vpc.id

  tags = {
    Name = "dev-gateway"
  }
}

resource "aws_route_table" "test-route_table" {
  vpc_id = aws_vpc.test-vpc.id

  tags = {
    Name = "dev_public_rt"
  }
}

resource "aws_route" "test-default_route" {
  route_table_id         = aws_route_table.test-route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.test-internet_gateway.id
}

resource "aws_route_table_association" "test-rta" {
  subnet_id      = aws_subnet.test-subnet.id
  route_table_id = aws_route_table.test-route_table.id
}

resource "aws_security_group" "test-sg" {
  name        = "dev_eg"
  description = "dev security group"
  vpc_id      = aws_vpc.test-vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_key_pair" "test-keypair" {
  key_name   = "dipokey1"
  public_key = file("~/.ssh/dipokeypair.pub")
}


resource "aws_instance" "test-intance" {
  instance_type          = "t2.micro"
  ami                    = data.aws_ami.test-ami.id
  key_name               = aws_key_pair.test-keypair.id
  vpc_security_group_ids = [aws_security_group.test-sg.id]
  subnet_id              = aws_subnet.test-subnet.id
  user_data              = file("userdata.tpl")

  root_block_device {
    volume_size = 10
  }

  tags = {
    Name = "dev-instance"
  }


#N.B: Another ways of setup instance with below terraform script

  //resource "aws_instance" "web" {
  //ami           = "ami-09cb80360d5069de4"
  //instance_type = "t3.micro"

  //tags = {
    //Name = "HelloWorld"
  //}
//}

  provisioner "local-exec" {
  command = templatefile("windows-ssh-config.tpl",{
  hostname = self.public_ip,
  user = "ubuntu",
  identityfile = "~/.ssh/dipokeypair"
  })
  interpreter = ["Powershell", "-command"]
  #interpreter = ["bash", "-c"]

  }

}



