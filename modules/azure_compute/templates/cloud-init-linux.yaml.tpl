#cloud-config
write_files:
- content: |
    LANG=en_US.utf-8
    LC_ALL=en_US.utf-8
  path: /etc/environment
