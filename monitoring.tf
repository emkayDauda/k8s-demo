data "kubectl_file_documents" "monitoring-namespace-manifest" {
  content = file("./manifests/monitoring/base/00-monitoring-ns.yaml")
  depends_on = [
    kubectl_manifest.services
  ]
}

resource "kubectl_manifest" "monitoring-namespace" {
  yaml_body = data.kubectl_file_documents.monitoring-namespace-manifest.content
  force_new = true
}

data "kubectl_filename_list" "monitoring_manifests" {
  pattern = "./manifests/monitoring/rest/*.yaml"
}

resource "kubectl_manifest" "monitoring_services" {
  depends_on = [kubectl_manifest.monitoring-namespace]
  count      = length(data.kubectl_filename_list.monitoring_manifests.matches)
  yaml_body  = file(element(data.kubectl_filename_list.monitoring_manifests.matches, count.index))
}
