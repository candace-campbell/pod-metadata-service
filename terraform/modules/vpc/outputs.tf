output "vpc_id" {
  value = aws_vpc.main.id
}

output "cluster_subnet_ids" {
  value = [aws_subnet.cluster_a.id, aws_subnet.cluster_b.id]
}

output "ng_subnet_ids" {
  value = [aws_subnet.ng_a.id, aws_subnet.ng_b.id]
}