output "instructions" {
  value     = <<-EOT
  Shapeblock has been successfully installed.

  Here are the next steps:
  %{ if var.cluster_dns != null }
  1. If you've added a domain, please go to your DNS provider and add the following DNS entries:
      A record - ${var.cluster_dns} ${local.ingress_ip}
      CNAME - *.${var.cluster_dns} ${var.cluster_dns}
  2. You can access the Shapeblock API using the sb-cli command. The latest version can be downloaded here: https://github.com/shapeblock/sb-cli/releases/latest
  3. You can login to Shapeblock using sb-cli with the following credentials:
      server: https://sb.${var.cluster_dns}
      username: ${var.sb_user}
      password: ${nonsensitive(local.sb_password)}
  For more details, check the docs: https://docs.shapeblock.com/
  %{ else }
  1. You can access the Shapeblock API using the sb-cli command. The latest version can be downloaded here: https://github.com/shapeblock/sb-cli/releases/latest
  2. Port forward the API service:
      kubectl port-forward svc/shapeblock-api -n shapeblock 8000:8000
  3. You can login to Shapeblock using sb-cli with the following credentials:
      server: http://localhost:8000
      username: ${var.sb_user}
      password: ${nonsensitive(local.sb_password)}
  For more details, check the docs: https://docs.shapeblock.com/
  %{ endif }
  EOT
  sensitive = false
}
