locals {
    enable_swap_volume = contains(
                    [
                        "RHEL-8.1", "RHEL-8.2", "RHEL-8.4", "RHEL-8.6", "RHEL-8.8","RHEL-9.0",
                        "Ubuntu-18.04-LTS", "Ubuntu-20.04-LTS", "OracleLinux-8.3","OracleLinux-8.9","RockyLinux-9"
                    ], var.os_version)

    backup_schedule = {
                    "no"      = "{\"version\":\"1.0\",\"wk_backup_schedule\":\"null\",\"wk_backup_retention\":{\"days\":\"\",\"weekly\":\"\",\"monthly\":\"\", \"yearly\":\"\"}}"
                    "days"    = "{\"version\":\"1.0\",\"wk_backup_schedule\":\"xxxx\",\"wk_backup_retention\":{\"days\":\"30\",\"weekly\":\"\",\"monthly\":\"\", \"yearly\":\"\"}}"
                    "weekly"  = "{\"version\":\"1.0\",\"wk_backup_schedule\":\"xxxx\",\"wk_backup_retention\":{\"days\":\"\",\"weekly\":\"13\",\"monthly\":\"\", \"yearly\":\"\"}}"
                    "monthly" = "{\"version\":\"1.0\",\"wk_backup_schedule\":\"xxxx\",\"wk_backup_retention\":{\"days\":\"\",\"weekly\":\"\",\"monthly\":\"24\", \"yearly\":\"\"}}"
                }
}
                