variable "vpc-cidr" {
  default = "10.0.0.0/16"
}

variable "pubsub01-cidr" {
  default = "10.0.1.0/24"
}
variable "pubsub02-cidr" {
  default = "10.0.2.0/24"

}
variable "prvtsub01-cidr" {
  default = "10.0.3.0/24"
}
variable "prvtsub02-cidr" {
  default = "10.0.4.0/24"
}
variable "all-cidr" {
  default = "0.0.0.0/0"
}
variable "az1" {
  default = "eu-west-3a"
}
variable "az2" {
  default = "eu-west-3b"
}

variable "ssl-certiciate-arn" {
    default =  "arn:aws:acm:eu-west-3:771737530389:certificate/cb67fc55-9ac0-48c0-b75e-cc96ad21d46d"
}

variable "operator_email" {
    default = "mendezmedusa0072@gmail.com"
  
}

variable "database_snaphot_identifier" {
    default = "arn:aws:rds:eu-west-3:771737530389:snapshot:fleetcart-finalsnapshot"
  
}

variable "database_instance_class" {
    default = "db.t2.micro"
  
}

variable "database_instance_identifier" {
    default = "webserver-rds-db"
  
}
variable "multi_az-deployment" {
    default = false
  
}
variable "ec2_ami_id" {
    default = "ami-0fcc7fc67ab38248c"
  
}

variable "ec2_instance_type" {
    default = "t2.micro"
  
}

variable "ec2_keypair_name" {
    default = "DepWeb-keypair"
  
}

variable "domain_name" {
    default = "mendezmedusa.com"
  
}
variable "record_name" {
    default = "www"
  
}