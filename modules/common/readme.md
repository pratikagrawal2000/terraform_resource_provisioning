## Inputs

| Name | Description | Type | Accepted values | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_wk_division_code"></a> [wk\_division\_code](#input\_wk\_division\_code) | WK Divison Code | `string` | Start with 'd' followed by three digits (e.g.,d123).| yes |
| <a name="input_wk_bu_code"></a> [wk\_bu_code](#input\wk\_bu_\code) | WK BU Code. | `string` | Start with 'b' followed by three digits (e.g., b123).| yes |
| <a name="input_wk_application_bit_id"></a> [wk_application_bit_id](#input\_wk_application_bit_id) | WK Application Bit ID | `string` | Exactly 12 characters long and can contain letters and digits.| yes |
| <a name="input_wk_application_name"></a> [wk_application_name](#input\_wk_application_name) | WK Application Name | `string` | Start and end with a lowercase letter or digit and can only contain lowercase letters, digits, spaces, dots, underscores and hyphens.| yes |
| <a name="input_wk_environment_name"></a> [wk_environment_name](#input\_wk_environment_name) | WK Environment Name | `string` | Accepts any one of the value dev, tst, int, qae, stg, uat, prd, dre, non, lte.| yes |
| <a name="input_wk_resource_class"></a> [wk_resource_class](#input\_wk_resource_class) | WK Resource Class | `string` | Start and end with an alphanumeric character and can contain alphanumeric characters, underscores, dots, hyphens and spaces in between.| yes |
| <a name="input_wk_resource_name"></a> [wk_resource_name](#input\_wk_resource_name) | WK Resource Name | `string` | Start and end with an alphanumeric character and can contain alphanumeric characters, underscores, dots, hyphens and spaces in between.| yes |
| <a name="input_wk_requestor"></a> [wk_requestor](#input\_wk_requestor) | WK Requestor mail id. | `string` | Email.id should be firstname.lastname@wolterskluwer.com.| yes |
| <a name="input_wk_business_owner"></a> [wk_business_owner](#input\_wk_business_owner) | WK Business Owner mail id | `string` | Email.id should be firstname.lastname@wolterskluwer.com.| yes |
| <a name="input_wk_technical_owner"></a> [wk_technical_owner](#input\_wk_technical_owner) | WK Technical Owner mail id | `string` | Email.id should be firstname.lastname@wolterskluwer.com.| yes |
| <a name="input_wk_app_support_group"></a> [wk_app_support_group](#input\_wk_app_support_group) | WK App Support Group | `string` | Provide valid Rainier assignment group.| yes |
| <a name="input_wk_infra_support_group"></a> [wk_infra_support_group](#input\_wk_infra_support_group) | WK Infra Support Group | `string` | Provide valid Rainier assignment group.| yes |
