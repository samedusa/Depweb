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
