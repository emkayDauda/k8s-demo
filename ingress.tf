data "kubectl_file_documents" "ingress_manifest" {
  content = file("./manifests/ingress.yaml")
}

resource "kubectl_manifest" "ingress" {
  yaml_body = data.kubectl_file_documents.ingress_manifest.content
  force_new = true
}