#!/usr/bin/env bash
main() {

  local -r dirname="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

  # Clean up cluster1
  kubectx cluster1
  # Force the CRD to be removed first as specifed in the k8s-registrar docs.
  kubectl delete -f  "${dirname}"/spiffeid.spiffe.io_spiffeids.yaml
  helm uninstall cluster1 --wait
  kubectl delete -f simple_deployment.yaml
  kubectl delete -f "${dirname}"/../cilium.yaml
 
  # Clean up cluster2
  kubectx cluster2
  helm uninstall cluster2 --wait

  container_id_cluster1=$(docker container ls | grep cluster1 | cut -d" " -f 1)
  container_id_cluster2=$(docker container ls | grep cluster2 | cut -d" " -f 1)

  # Disconnect bridges
  docker network disconnect cluster2 "${container_id_cluster1}"
  docker network disconnect cluster1 "${container_id_cluster2}"

  exit 0
}
main "$@"
