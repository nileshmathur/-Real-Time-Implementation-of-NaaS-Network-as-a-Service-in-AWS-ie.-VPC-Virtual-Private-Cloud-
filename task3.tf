provider "aws" {
	region = "ap-south-1"
	profile = "nileshmathur"                  #Specifying AWS as provider         

}
##########################################################################################################
resource "aws_vpc" "nilesh_vpc" {
	cidr_block 			 = "192.168.0.0/16"
	instance_tenancy 	 = "default"                        #Creating VPC
	enable_dns_hostnames = "true"
	
	tags = {
		Name = "nilesh_vpc"
	}
}
#######################################################################################################
resource "aws_subnet" "pub_subnet" {
	depends_on 			= [ aws_vpc.nilesh_vpc ,]
	
	vpc_id 				= aws_vpc.nilesh_vpc.id                       #Creating Public Subnet
	cidr_block 			= "192.168.0.0/24"
	availability_zone 	= "ap-south-1a"
	map_public_ip_on_launch  = "true"
	
	tags = {
		Name = "pub_subnet"
	}
}

resource "aws_subnet" "pri_subnet" {
	depends_on 			= [ aws_vpc.nilesh_vpc ,]                  #Creating Private Subnet
	
	vpc_id 				= aws_vpc.nilesh_vpc.id
	cidr_block 			= "192.168.1.0/24"
	availability_zone 	= "ap-south-1b"
	
	tags = {
		Name = "pri_subnet"
	}
}
###########################################################################################################
resource "aws_internet_gateway" "nilesh_ig" {
	depends_on 			= [ aws_vpc.nilesh_vpc ,]
	
	vpc_id 				= aws_vpc.nilesh_vpc.id                    #Creating Internet Gateway
	
	tags = {
		Name = "nilesh_ig"
	}
}
##########################################################################################################
resource "aws_route_table" "nilesh_rt" {
	depends_on 			= [ aws_vpc.nilesh_vpc ,]
	
	vpc_id 			    = aws_vpc.nilesh_vpc.id
	route {
		cidr_block 		= "0.0.0.0/0"
		gateway_id 		= aws_internet_gateway.nilesh_ig.id                       #Creating Routing Table
    }
  
	tags = {
		Name = "nilesh_rt"
	}
}
###########################################################################################################################################3
resource "aws_route_table_association" "pub_subnet_rt" {
	depends_on 			= [ aws_route_table.nilesh_rt , aws_subnet.pub_subnet ]              
	
	subnet_id 			= aws_subnet.pub_subnet.id                              #Associating Routing Table with Public Subnet
	route_table_id 		= aws_route_table.nilesh_rt.id
}
##########################################################################################################################################
resource "tls_private_key" "key_pair" {
	algorithm 			= "RSA"
}


resource "aws_key_pair" "key" {
	depends_on 			= [ tls_private_key.key_pair ,]                       #Creating Key Pair
	
	key_name 			= "arpitT1"
	public_key 			= tls_private_key.key_pair.public_key_openssh

}
######################################################################################################################################
resource "aws_security_group" "wp_sg" {
	depends_on 			= [ aws_vpc.nilesh_vpc ,]
	
	name        		= "wp_allow"
	description 		= "https and ssh"
	vpc_id      		= aws_vpc.nilesh_vpc.id


	ingress {
		from_port   = 22
		to_port     = 22
		protocol    = "tcp"
		cidr_blocks = ["0.0.0.0/0"]                     #Creating Security Group for WordPress
	}
  
	ingress {
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
		Name ="wp_allow"
	}
}
##########################################################################################################
resource "aws_security_group" "msql_sg" {
	depends_on 			= [ aws_vpc.nilesh_vpc ,]
	
	name        	= "msql_allow"
	description 	= "mysql_allow_port_3306"
	vpc_id      	= aws_vpc.nilesh_vpc.id                  #Creating Security Group for MYSQL


	ingress {
		from_port   = 3306
		to_port     = 3306
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
		Name =	"msql_allow"
	}
}
###########################################################################################################################
resource "aws_instance" "wp_os" {
	depends_on 			= [ aws_subnet.pub_subnet , aws_security_group.wp_sg]
	
	ami                	= "ami-000cbce3e1b899ebd" 
    instance_type      	= "t2.micro"
    key_name       	   	= aws_key_pair.key.key_name
    security_groups	 	= [aws_security_group.wp_sg.id ,]             #Launching WordPress instance
    subnet_id       	= aws_subnet.pub_subnet.id
 
	tags = {
		Name = "wp_os"
	}
}
###########################################################################################################################
resource "aws_instance" "mysql_os" {
	depends_on 			= [ aws_subnet.pri_subnet , aws_security_group.msql_sg]
	
	ami           		= "ami-08706cb5f68222d09"
	instance_type 		= "t2.micro"
	key_name 			= aws_key_pair.key.key_name
	security_groups 	= [aws_security_group.msql_sg.id ,]            #Launching MYSQL instance
	subnet_id 			= aws_subnet.pri_subnet.id
 
	tags = {
		Name = "mysql_os"
	}
}
############################################################################################################################
output "wordpress_ip" {
	value 				= aws_instance.wp_os.public_ip        #Printing the Public IP of WordPress on command prompt
}

##########################################################################################################################



