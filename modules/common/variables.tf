variable "wk_division_code" {
  description = "WK Division Code"
  type        = string

  validation {
    condition     = can(regex("^d\\d{3}$", var.wk_division_code))
    error_message = "The WK Division Code must start with 'd' followed by three digits (e.g., d123)."
  }
}
variable "wk_bu_code" {
  description = "WK BU Code"
  type        = string

  validation {
    condition     = can(regex("^b\\d{3}$", var.wk_bu_code))
    error_message = "The WK BU Code must start with 'b' followed by three digits (e.g., b123)."
  }
}
variable "wk_application_bit_id" {
  description = "WK Application Bit ID"
  type        = string

  validation {
    condition     = can(regex("^[A-z0-9]{12}$", var.wk_application_bit_id))
    error_message = "The WK Application Bit ID must be exactly 12 characters long and can only contain letters and digits."
  }
}
variable "wk_application_name" {
  description = "WK Application Name"
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9\\s._-]*[a-z0-9]$", var.wk_application_name))
    error_message = "The WK Application Name must start and end with a lowercase letter or digit and can only contain lowercase letters, digits, spaces, dots, underscores, and hyphens."
  }
}
variable "wk_requestor" {
  description = "WK Requestor"
  type        = string
  validation {
    condition     = can(regex("^[a-zA-Z0-9]+[.][a-zA-Z0-9]+@wolterskluwer\\.com$", var.wk_requestor))
    error_message = "The email.id should be firstname.lastname@wolterskluwer.com."
  }
}
variable "wk_business_owner" {
  description = "WK Bussines Owner"
  type        = string
  validation {
    condition     = can(regex("^[a-zA-Z0-9]+[.][a-zA-Z0-9]+@wolterskluwer\\.com$", var.wk_business_owner))
    error_message = "The email.id should be firstname.lastname@wolterskluwer.com."
  }
}
variable "wk_technical_owner" {
  description = "WK Technical Owner"
  type        = string
  validation {
    condition     = can(regex("^[a-zA-Z0-9]+[.][a-zA-Z0-9]+@wolterskluwer\\.com$", var.wk_technical_owner))
    error_message = "The email.id should be firstname.lastname@wolterskluwer.com."
  }
}
variable "wk_app_support_group" {
  description = "WK App Support Group"
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9][\\w\\.\\-\\s]*[a-z0-9]$", var.wk_app_support_group))
    error_message = "Please provide valid Rainier assignment group."
  }
}
variable "wk_infra_support_group" {
  description = "WK Infra Support Group"
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9][\\w\\.\\-\\s]*[a-z0-9]$", var.wk_infra_support_group))
    error_message = "Please provide valid Rainier assignment group."
  }
}
variable "wk_environment_name" {
  description = "WK Environment Name"
  type        = string
  validation {
    condition     = can(regex("^(dev|tst|int|qae|stg|uat|prd|dre|non|lte)$", var.wk_environment_name))
    error_message = "Please provide any one of the value (dev|tst|int|qae|stg|uat|prd|dre|non|lte)."
  }
}
variable "wk_resource_class" {
  description = "WK Resource Class"
  type        = string
  validation {
    condition     = can(regex("^[a-zA-Z0-9][\\w\\.\\-\\s]*[a-zA-Z0-9]$", var.wk_resource_class))
    error_message = "The WK Resource Class must start and end with an alphanumeric character and can contain alphanumeric characters, underscores, dots, hyphens and spaces in between."
  }
}
variable "wk_resource_name" {
  description = "WK Resource Name"
  type        = string
  validation {
    condition     = can(regex("^[a-zA-Z0-9][\\w\\.\\-\\s]*[a-zA-Z0-9]$", var.wk_resource_name))
    error_message = "The WK Resource Name must start and end with an alphanumeric character and can contain alphanumeric characters, underscores, dots, hyphens and spaces in between."
  }
}
