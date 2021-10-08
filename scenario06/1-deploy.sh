#!/usr/bin/env bash

# Brief: Deploy cilium, registrar, spire and workload to separated clusters.

# Details
# Deploy spire-server cluster2
# Change spire-agent server_address and server port based on the spire-server-0 
# Change registrar server_address and server port based on the spire-server-0 
# Generate token and update spire-agent manifest
# Deploy CRD, spire-agent, registrar cluster1
# Deploy nginx

main() {

  local -r dirname="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  local -r filename="${dirname}/$(basename "${BASH_SOURCE[0]}")"
  local -r user="kubeconfig-sa"
  
  if ! command -v helm &> /dev/null
  then
    echo "helm not found!! How to install: https://helm.sh/docs/intro/install/"
    exit
  fi
  if ! command -v jq &> /dev/null
  then
    echo "jq not found! You can use your package manager to install it."
    exit
  fi

  "${dirname}"/2-cleanup.sh 2> /dev/null

  kubectl config use-context cluster1

  ca_data=$(kubectl config view -o json --flatten | jq --raw-output '.clusters[] | select (.name == "cluster1") | .cluster."certificate-authority-data"')
  cluster_address=$(kubectl config view -o json | jq --raw-output '.clusters[] | select (.name == "cluster1") | .cluster."server"')
  echo "Obtain the name of the service account authentication token and assign its value to an environment variable"
  token_name=`kubectl -n kube-system get serviceaccount/"${user}" -o jsonpath='{.secrets[0].name}'`
  echo "Obtain the value of the service account authentication token and assign its value (decoded from base64) to an environment variable"
  token=`kubectl -n kube-system get secret "${token_name}" -o jsonpath='{.data.token}'| base64 --decode`

  kubectl config use-context cluster2
  echo "# Deploy spire-server cluster2"
  helm install cluster2 cluster2 \
    --set certificateAuthorityData="${ca_data}" \
    --set clusterAddress="${cluster_address}" \
    --set user="${user}" \
    --set token="${token}"

  kubectl get pods -A
  while [[ $(kubectl -n spire get pods spire-server-0 -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; do echo "waiting for pod" && sleep 4 && kubectl get pods -A; done

  # echo "# Add privileged registration entry for the registrar"
  # Registrar connects via unix socket to fetch the SVIDs through spire-agent
  # Registrar uses the SVIDs to establish a secure connection to spire-server
  node_uid=$(kubectl get nodes -o json --context cluster1 | jq .items[0].metadata.uid | awk -F\" '{print $2}')
  kubectl exec -n spire spire-server-0 -- \
    /opt/spire/bin/spire-server entry create \
    -spiffeID spiffe://example.org/registrar \
    -parentID spiffe://example.org/spire/agent/k8s_psat/demo-cluster/"${node_uid}" \
    -selector k8s:pod-label:app:spire-server \
    -selector unix:uid:0 \
    -admin

  # FIXME navarrothiago: THERE IS AN INTERMITTENT PROBLEM IF WE NOT WAIT. 
  # THE spiffe://example.org/k8s-workload-registrar/demo-cluster/node/cluster1 IS NOT CREATED (sometimes)
  # We got the following error messages on registrar 
  # time="2021-10-27T18:46:31Z" level=error msg="Unable to update or create registration entry" error="rpc error: code = PermissionDenied desc = authorization denied for method /spire.api.server.entry.v1.Entry/BatchCreateEntry" name=cluster1 namespace=spire
  # time="2021-10-27T18:46:32Z" level=error msg="Unable to update or create registration entry" error="rpc error: code = PermissionDenied desc = authorization denied for method /spire.api.server.entry.v1.Entry/BatchCreateEntry" name=nginx-deployment-7ffbd8bd54-gkxq6 namespace=default
  # On spire server 
  # time="2021-10-27T18:46:28Z" level=error msg="Failed to authenticate caller" caller_addr="172.17.0.1:49687" caller_id="spiffe://example.org/ciliumagent" error="rpc error: code = PermissionDenied desc = authorization denied for method /spire.api.server.entry.v1.Entry/BatchCreateEntry" method=BatchCreateEntry request_id=236e9c47-edec-4860-998c-eabe037cbec1 service=entry.v1.Entry subsystem_name=api
  # On spire agent
  # time="2021-10-27T18:29:02Z" level=error msg="Unable to update or create registration entry" error="rpc error: code = PermissionDenied desc = authorization denied for method /spire.api.server.entry.v1.Entry/BatchCreateEntry" name=cluster1 namespace=spire
  # time="2021-10-27T18:29:02Z" level=error msg="Unable to update or create registration entry" error="rpc error: code = PermissionDenied desc = authorization denied for method /spire.api.server.entry.v1.Entry/BatchCreateEntry" name=nginx-deployment-7ffbd8bd54-twhm9 namespace=default

  kubectl exec -n spire spire-server-0 -- \
    /opt/spire/bin/spire-server entry create \
    -spiffeID spiffe://example.org/ciliumagent \
    -parentID spiffe://example.org/spire/agent/k8s_psat/demo-cluster/"${node_uid}" \
    -selector unix:uid:0 \
    -admin

  # Must be before the configuration of the docker network to avoid the error
  # Error getting ip from host: container addresses should have 2 values, got 3
  echo "# Change spire-agent server_address and server_port based on the spire-server-0"
  desired_server_ip=$(minikube service --url spire-server -p cluster2 -n spire --https | cut -d':' -f 2 | cut -b 3-)
  desired_server_port=$(minikube service --url spire-server -p cluster2 -n spire --https | cut -d':' -f 3)

  container_id_cluster1=$(docker container ls | grep cluster1 | cut -d" " -f 1)
  container_id_cluster2=$(docker container ls | grep cluster2 | cut -d" " -f 1)


  # Connect bridges
  docker network connect cluster2 "${container_id_cluster1}"
  docker network connect cluster1 "${container_id_cluster2}"
  
  echo "# Deploy cilium, CRD, spire-agent, registrar to cluster1"
  kubectl config use-context cluster1
  kubectl apply -f "${dirname}"/../cilium.yaml
  kubectl apply -f spiffeid.spiffe.io_spiffeids.yaml

  helm install cluster1 cluster1 \
    --set spireServerAddress="${desired_server_ip}" \
    --set spireServerPort="${desired_server_port}"
  while [[ $(kubectl -n spire get pods spire-server-0 -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; do echo "waiting for pod" && sleep 4 && kubectl get pods -A; done

  # echo "# Deploy nginx workload to cluster1"
  kubectl apply -f simple_deployment.yaml

  exit 0
}

main "$@"
