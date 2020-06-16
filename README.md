# Web hosting by using AWS cloud with terraform
## Introduction:
**Cloud automation** n is a broad term that refers to the processes and tools an organization uses to reduce the manual efforts associated with provisioning and managing cloud computing workloads. IT teams can apply cloud automation to **private, public and **hybrid cloud environments.

## Problem Statement:
1. Create the *key* and *security group* which allow the port 80.
2. Launch *EC2 instance.
3. In this Ec2 instance use the key and security group which we have created in step 1.
4. Launch one *Volume (EBS)* and mount that volume into /var/www/html
5. Developer have uploded the code into github repo also the repo has some images.
6. Copy the github repo code into /var/www/html
7. Create *S3 bucket,* and copy/deploy the images from github repo into the s3 bucket and change the permission to public readable.
8 Create a Cloudfront using s3 bucket(which contains images) and use the Cloudfront URL to  update in code in /var/www/html.

### Resources/Services used
1. EC2
2. EBS
3. S3
4. cloudFront
5. terraform
6. Github

   ### 1. Create the *key* and *security group* which allow the port 80.
   **KEY Pair**
Amazon AWS uses key pair to encrypt and decrypt login information. A sender uses a public key to encrypt data, which its receiver then decrypts using another private key. These two keys, public and private, are known as a key pair. You need a key pair to be able to connect to your instances.
~~~
resource "tls_private_key" "key_pair" {
  algorithm = "RSA"
}
resource "local_file" "private_key" {
  content = tls_private_key.key_pair.private_key_pem
  filename = "web_hosting_key.pem"
  file_permission = 0777
}


resource "aws_key_pair" "key_pair" {
  key_name   = "web_hosting_key"
  public_key = tls_private_key.key_pair.public_key_openssh
}
~~~


when we check AWS GUI. key pair are generated.

![key pair](https://github.com/cybshark/Clous_web_hosting/blob/master/keypair.JPG)

**What is SG AWS?**

A *security group* acts as a virtual firewall for your instance to control incoming and outgoing traffic. ... When Amazon EC2 decides whether to allow traffic to reach an instance, it evaluates all of the rules from all of the security groups that are associated with the instance.

**Terraform code for SG**
~~~
resource "aws_security_group" "allow_http" {
  name        = "port_allow"
  description = "Allow HTTP SSH inbound traffic"
  vpc_id      = "vpc-d4ebf6bc"

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }


  tags = {
    Name = "web_hosting_http"
  }
}

~~~

**The AWS SG are created.**


![SG](https://github.com/cybshark/Clous_web_hosting/blob/master/SG.JPG)
 
 ### 2.Launch *EC2 instance.

An EC2 instance is a virtual server in Amazon's Elastic Compute Cloud (EC2) for running applications on the Amazon Web Services (AWS) infrastructure.

~~~
resource "aws_instance" "web_hosting" {
	ami		= "ami-005956c5f0f757d37"
	instance_type	="t2.micro"
	key_name          = "web_hosting_key"
  	security_groups   = [ "port_allow" ]

	tags = {
		Name = "Task1"
	}
}
~~~

After creating instance we need to log in instance and install apache web server and start services.
for this we need to add plugin remote-exce provisioner.
~~~
 provisioner "remote-exec" {
    	inline = [
      	"sudo yum install httpd  -y",
      	"sudo service httpd start",
      	"sudo service httpd enable"
    	]
 	 }

~~~

## 4. Launch one *Volume (EBS)* and mount that volume into /var/www/html

What is EBS AWS?
**Amazon Elastic Block Store (EBS)** is a block storage system used to store persistent data. Amazon EBS is suitable for EC2 instances by providing highly available block level storage volumes. It has three types of volume, i.e. General Purpose (SSD), Provisioned IOPS (SSD), and Magnetic.

~~~
resource "aws_ebs_volume" "web_hosting_ebs" {
  availability_zone = aws_instance.myweb.availability_zone
  size              = 1

  tags = {
    Name = "tsak1_ebs"
  }
}
~~~

Attached & Mount the EBS to EC2 instance.

~~~
// Attaching EBS volume
resource "aws_volume_attachment" "ebs_vol" {
   device_name = "/dev/sdh"
   volume_id   =  "vol-0f619afd4ff608fe3"
   instance_id = "i-014b9bc309a702237"
   depends_on = [
       aws_ebs_volume.MyVol1,
       aws_instance.web_hosting
   ]
 }
 // Used for configuration and mounting
resource "null_resource" "web_remote"  {

depends_on = [
    aws_volume_attachment.ebs_vol,
]

connection {
    type = "ssh"
    user = "ec2-user"
    private_key = file("C:\Users\visha\Downloads\mykey.pem")
    host = aws_instance.myin3.public_ip
}
provisioner "remote-exec" {
    inline = [
      "sudo mkfs.ext4  /dev/xvdf",
      "sudo mount  /dev/xvdf  /var/www/html",
      "sudo rm -rf /var/www/html/*",
      "sudo git clonehttps://github.com/cybshark/Clous_web_hosting.git /var/www/html/"
    ]
  }
}
~~~

## 7. Create *S3 bucket,* and copy/deploy the images from github repo into the s3 bucket and change the permission to public readable.

An Amazon S3 bucket is a public cloud storage resource available in Amazon Web Services' (AWS) Simple Storage Service (S3), an object storage offering. Amazon S3 buckets, which are similar to file folders, store objects, which consist of data and its descriptive metadata

~~~
\\ Creating S3 bucket
resource "aws_s3_bucket" "web_hosting_bucket" {
  bucket = "web_hosting_s3"
  acl    = "public-read"
}
\\ Uploading file to S3 bucket
resource "aws_s3_bucket_object" "object" {
  bucket = "web_hosting_s3"
  key    = "img.jpg"
  source = "img.jpg"
  acl = "public-read"
  content_type = "image/jpg"
  depends_on = [
      aws_s3_bucket.MyTerraformHwaBuckket
  ]
}
~~~
## 8 Create a Cloudfront using s3 bucket(which contains images) and use the Cloudfront URL to  update in code in /var/www/html.

CloudFront delivers your content through a worldwide network of data centers called edge locations. When a user requests content that you're serving with CloudFront, the user is routed to the edge location that provides the lowest latency (time delay), so that content is delivered with the best possible performance.

~~~
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
~~~

After All Code building. we create one tf file and run ***terraform apply*** this is Aws create new instance and ebs after creating ebs attached with EC2 instance. after that install httpd server and copy the code form github and paste inside /var/www/html folder after that cloud front create edge. when client click on cloudfront url so we easly acces web page and image.

![output](https://github.com/cybshark/Clous_web_hosting/blob/master/image%20s3.JPG)


More information [Click here](https://www.terraform.io/docs/providers/aws/index.html)

If any suggestion [Click here](https://www.linkedin.com/in/vishal-dalvi-490b07134/)

                                                ## THANK YOU !!!

