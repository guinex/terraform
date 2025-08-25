variable "postgres_user" {
  description = "Postgres username"
  type        = string
}

variable "postgres_password" {
  description = "Postgres password"
  type        = string
  sensitive   = true
}

variable "postgres_db" {
  description = "Default Postgres database name"
  type        = string
  default     = "orderdb"
}