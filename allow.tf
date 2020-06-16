provider "aws" {
   access_key = "AKIAJCV4YYAE4VS7ZVZQ"
   secret_key = "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"
   region     = "ap-south-1"
    
}
#Creating S3 bucket
resource "aws_s3_bucket" "MyTerraformHwaBuckket" {
  bucket = "adnantaskbucket1"
  acl    = "public-read"
}
#Uploading file to S3 bucket
resource "aws_s3_bucket_object" "object" {
  bucket = "adnantaskbucket1"
  key    = "img.jpg"
  source = "img.jpg"
  acl = "public-read"
  content_type = "image/jpg"
  depends_on = [
      aws_s3_bucket.MyTerraformHwaBuckket
  ]
}
#Creating Cloud-front and attching S3 buccket to it
resource "aws_cloudfront_distribution" "myCloudfront1" {
    origin {
        domain_name = "adnantaskbucket1.s3.amazonaws.com"
        origin_id   = "S3-adnantaskbucket1" 

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
        target_origin_id = "S3-adnantaskbucket1"

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
    depends_on = [
        aws_s3_bucket_object.object
    ]
}
#Create Security group
resource "aws_security_group" "allowtsl" {
  name        = "allowtls"
  description = "Allow TLS inbound traffic"
  vpc_id      = "vpc-e0e9f488"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }

  ingress {
    description = "TLS from VPC"
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
    Name = "allowtls"
  }
}
#Create EBS volume
resource "aws_ebs_volume" "MyVol1" {
  availability_zone = "ap-south-1a"
  size = 1
  tags = {
    Name = "MyVolume"
  }
}
#Create EC2 instance
resource "aws_instance" "myin3" {
    ami = "ami-052c08d70def0ac62"
    instance_type = "t2.micro"
    key_name = "mykey"
    security_groups = [ "allowtls"  ]
    connection {
        type = "ssh"
        user = "ec2-user"
        private_key = file("C:\Users\visha\Downloads\mykey.pem")
        host = aws_instance.myin3.public_ip
    }
    provisioner "remote-exec" {
        inline = [
            "sudo yum install httpd  php git -y",
            "sudo systemctl restart httpd",
            "sudo systemctl enable httpd",
        ]
    }

    tags = {
        Name = "LinuxWorld 1"
    }
}
#Attaching EBS volume
resource "aws_volume_attachment" "AttachVol" {
   device_name = "/dev/sdh"
   volume_id   =  "vol-0f619afd4ff608fe3"
   instance_id = "i-014b9bc309a702237"
   depends_on = [
       aws_ebs_volume.MyVol1,
       aws_instance.myin3
   ]
 }
 #Used for configuration and mounting
resource "null_resource" "adnanremote3"  {

depends_on = [
    aws_volume_attachment.AttachVol,
]

connection {
    type = "ssh"
    user = "ec2-user"
    private_key = file("F:/HMCC/adnan1818.pem")
    host = aws_instance.myin3.public_ip
}
provisioner "remote-exec" {
    inline = [
      "sudo mkfs.ext4  /dev/xvdf",
      "sudo mount  /dev/xvdf  /var/www/html",
      "sudo rm -rf /var/www/html/*",
      "sudo git clone https://github.com/Aadnan1007/Terraform-Task-1.git /var/www/html/"
    ]
  }
}