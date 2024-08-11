output "kubeconfig" {
  value     = data.remote_file.kubeconfig.content
  sensitive = false
}
