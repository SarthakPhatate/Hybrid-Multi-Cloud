// Defining the provider and region

provider "aws" {
  region     = "ap-south-1"
  profile    = "sarthakphatate"
}

// Creating the key for remote login or SSH

resource "tls_private_key" "skey" {
  algorithm  = "RSA"
  rsa_bits   = 4096
}
resource "aws_key_pair" "sshkey" {
  key_name   = "sshkey"
  public_key = tls_private_key.skey.public_key_openssh
}


// Creating the Security Group allowing port 22 and port 80 to accessed by anyone

resource "aws_security_group" "security" {
  name        = "security"
  description = "Allow traffic on port 80 and 22"
  vpc_id = "vpc-8f041ce7"

  ingress {
    description = "incoming http"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "incoming ssh"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "nfs"
    from_port   = 2049
    to_port     = 2049
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
    Name = "security"
  }
}

// Creating EBS volume to store data

resource "aws_efs_file_system" "efs1" {
  creation_token = "efs"
  tags = {
    Name = "HMC-efs"
  }
}

// Attaching the efs volume to ec2 instance

resource "aws_efs_mount_target" "efs1_att" {
  depends_on = [
    aws_security_group.security,
  ]
  file_system_id = aws_efs_file_system.efs1.id
  subnet_id = "subnet-7c6e6f14"
  security_groups = [aws_security_group.security.id]
}

// Creating EC2 instance with  

resource "aws_instance" "app" {
  depends_on = [
    aws_key_pair.sshkey,
    aws_security_group.security,
  ]
  ami           = "ami-0447a12f28fddb066"
  instance_type = "t2.micro"
  key_name = "sshkey"
  security_groups = [aws_security_group.security.id]
  subnet_id = "subnet-7c6e6f14"

  connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = tls_private_key.skey.private_key_pem
    host     = aws_instance.app.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum install httpd  php git -y",
      "sudo systemctl restart httpd",
      "sudo systemctl enable httpd",
      "sudo yum install nfs-utils amazon-efs-utils -y",
      "sudo mount -t efs ${aws_efs_file_system.efs1.id}:/ /var/www/html",
      "sudo echo ${aws_efs_file_system.efs1.id}:/ /var/www/html efs defaults, _netdev 0 0 >> sudo /etc/fstab",
      "sudo rm -f /var/www/html/*",
      "sudo git clone https://github.com/SarthakPhatate/HMC-task2-files.git /var/www/html/"
    ]
  }

  tags = {
    Name = "HMC-1"
  }
}

output "myos_ip" {
  value = aws_instance.app.public_ip
}

//Creating S3 bucket 

resource "aws_s3_bucket" "bucket" {
  bucket = "hmc1-bucket"
  acl = "public-read"
  
  tags = {
    Name = "bucket"
  }
}


resource "aws_cloudfront_origin_access_identity" "origin_access_identity_created" {

   depends_on = [aws_s3_bucket_object.object]
   comment = "first_origin_access_identity"
  
} 

output "first"{

  value = aws_cloudfront_origin_access_identity.origin_access_identity_created
 
}

//Creating CloudFrount

locals {
  s3_origin_id = "S3Origin"
}

resource "aws_cloudfront_distribution" "cloud" {
  origin {
    domain_name = aws_s3_bucket.bucket.bucket_regional_domain_name
    origin_id   = local.s3_origin_id
    
    custom_origin_config {
    http_port = 80
    https_port = 80
    origin_protocol_policy = "match-viewer"
    origin_ssl_protocols = ["TLSv1", "TLSv1.1", "TLSv1.2"] 
    }
  }
  enabled = true
  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id
  forwarded_values {
    query_string = false
  cookies {
      forward = "none"
      }
  }
  viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
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

resource "null_resource" "wepip"  {
 provisioner "local-exec" {
     command = "echo  ${aws_instance.app.public_ip} > publicip.txt"
 }
}

// uploading the image to S3 bucket
resource "aws_s3_bucket_object" "object" {
depends_on = [
    aws_s3_bucket.bucket,
  ]
  bucket = "hmc1-bucket"
  key    = "cloud.jpg"
  source = "cloud.jpg"

  etag = "${filemd5("cloud.jpg")}"
}
