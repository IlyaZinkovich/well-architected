variable "project_name" {
  default = "test"
}

variable "vpc" {
}

variable "private_subnets" {
  type = "list"
}

variable "public_subnets" {
  type = "list"
}

variable "alb_security_group" {
}

variable "app_port" {
  default = 8080
}

variable "fargate_cpu" {
  description = "Fargate instance CPU units to provision (1 vCPU = 1024 CPU units)"
  default     = "1024"
}

variable "fargate_memory" {
  description = "Fargate instance memory to provision (in MiB)"
  default     = "2048"
}

variable "aws_region" {
  description = "The AWS region where all resources will be created"
  default     = "eu-central-1"
}

variable "app_count" {
  description = "Number of docker containers to run"
  default     = 1
}

variable "application_security_group" {
}
