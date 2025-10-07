variable "aws_region" {
  description = "A regiao da AWS onde os recursos serao criados."
  type        = string
  default     = "us-east-2"
}

variable "project_name" {
  description = "O nome do projeto, usado como prefixo."
  type        = string
  default     = "coderag"
}
