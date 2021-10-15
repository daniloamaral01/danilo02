variable "vpc_id" {
    type = string
}

variable "subnet_cidr" {
    type = string 
}

variable "ssh_key" {
    type = string
}

variable "app_name" {
    type = string
}
variable "app_instance" {
    type = string
}
variable "db_instance" {
    type = string
}
variable "app_tags" {
    type = map
}