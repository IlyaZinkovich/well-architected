output "vpc" {
  value = "${aws_vpc.main.id}"
}

output "public_subnets" {
  value = ["${aws_subnet.public.*.id}"]
}

output "alb_security_group" {
  value = "${aws_security_group.alb.id}"
}
