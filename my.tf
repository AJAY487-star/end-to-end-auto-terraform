provider "aws" {
  region = "ap-south-1"
  profile = "pintu"
}

resource "aws_security_group" "sec-group2" {
  name        = "sec-group2"
  description = "Allow SSH and HTTP"
  vpc_id      = "vpc-a3534fcb"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sec-group2"
  }
}





resource "aws_instance" "web" {
  ami           = "ami-0447a12f28fddb066"
  instance_type = "t2.micro"
  key_name = "mykey11"
  security_groups = [ "sec-group2"]

  connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = file("C:/Users/Ajay Kumar/Downloads/mykey11.pem")
    host     = aws_instance.web.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum install httpd php git -y",
      "sudo systemctl restart httpd",
      "sudo systemctl enable httpd",
    ]
  }
  tags = {
    Name = "ajaytera2_OS"
  }
}


resource "aws_ebs_volume" "ebsstore" {
  availability_zone = aws_instance.web.availability_zone
  size              = 1
  tags = {
    Name = "ajay2ebs"
  }
}

resource "aws_volume_attachment" "ebs_att" {
  device_name = "/dev/sdh"
  volume_id   = "${aws_ebs_volume.ebsstore.id}"
  instance_id = "${aws_instance.web.id}"
  force_detach = true
}


output "OS_IP" {
   value = aws_instance.web.public_ip
}

resource "null_resource" "null_local"  {
     provisioner "local-exec" {
        command = "echo ${aws_instance.web.public_ip} > publicip.txt"
     }
}




resource "null_resource" "null_remote1" {

depends_on = [
     aws_volume_attachment.ebs_att,
  ]

  connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = file("C:/Users/Ajay Kumar/Downloads/mykey11.pem")
    host     = aws_instance.web.public_ip
  }

 provisioner "remote-exec" {
    inline = [
      "sudo mkfs.ext4 /dev/xvdh",
      "sudo mount /dev/xvdh /var/www/html",
      "sudo rm -rf /var/www/html/*",
      "sudo git clone https://github.com/AJAY487-star/multicloud.git /var/www/html/"
    ]
  }
}

resource "aws_s3_bucket" "buckettera00011" {
  bucket = "ajaybaket"
  acl    = "public-read"

  versioning {
    enabled = true
  }
 
  tags = {
    Name = "ajay-terra-bucket"
    Environment = "Dev"
  }
}

resource "aws_cloudfront_distribution" "cloudfront1" {
    origin {
        domain_name = "ajaybaket.s3.amazonaws.com"
        origin_id = "S3-ajaybaket"


        custom_origin_config {
            http_port = 80
            https_port = 80
            origin_protocol_policy = "match-viewer"
            origin_ssl_protocols = ["TLSv1", "TLSv1.1", "TLSv1.2"]
        }
    }
       
    enabled = true


    default_cache_behavior {
        allowed_methods = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
        cached_methods = ["GET", "HEAD"]
        target_origin_id = "S3-ajaybaket"

        forwarded_values {
            query_string = false
        
            cookies {
               forward = "none"
            }
        }
        viewer_protocol_policy = "allow-all"
        min_ttl = 0
        default_ttl = 3600
        max_ttl = 86400
    }
 
    restrictions {
        geo_restriction {
           
            restriction_type = "none"
        }
    }

    viewer_certificate {
        cloudfront_default_certificate = true

    }
}


resource "null_resource" "null_chrome"  {
depends_on = [
     null_resource.null_remote1,
  ]

     provisioner "local-exec" {
        command = "chrome ${aws_instance.web.public_ip}"
     }
}






