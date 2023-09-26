output "vpc_id" {
    value = aws_vpc.DepWeb-vpc.id
  
}

output "public-subnet01" {
    value = aws_subnet.DepWeb-pubsub01.id
  
}

output "public-subnet02" {
    value = aws_subnet.DepWeb-pubsub02.id
  
}
output "website_url" {
    value = join ("", ["https://", var.record_name, ".", var.domain_name])
  
}