#!/usr/bin/env bash
main() {
  minikube delete -p cluster1
  minikube delete -p cluster2

  # Cluster1 with CNI (cilium)
  minikube start --bootstrapper=kubeadm --memory 2048 --cpus 2 --profile cluster1 --network-plugin=cni --driver=docker \
                --extra-config=apiserver.authorization-mode=Node,RBAC \
                --extra-config=apiserver.service-account-signing-key-file=/var/lib/minikube/certs/sa.key \
                --extra-config=apiserver.service-account-key-file=/var/lib/minikube/certs/sa.pub \
                --extra-config=apiserver.service-account-issuer=api \
                --extra-config=apiserver.service-account-api-audiences=api,spire-server
  minikube ssh -p cluster1 -- sudo mount bpffs -t bpf /sys/fs/bpf

  # Cluster2 without CNI 
  minikube start --bootstrapper=kubeadm --memory 2048 --cpus 2 --profile cluster2 --driver=docker \
                --extra-config=apiserver.authorization-mode=Node,RBAC \
                --extra-config=apiserver.service-account-signing-key-file=/var/lib/minikube/certs/sa.key \
                --extra-config=apiserver.service-account-key-file=/var/lib/minikube/certs/sa.pub \
                --extra-config=apiserver.service-account-issuer=api \
                --extra-config=apiserver.service-account-api-audiences=api,spire-server

  kubectl config use-context cluster1
  echo "Create a new service account in the kube-system namespace"
  kubectl -n kube-system create serviceaccount kubeconfig-sa 
  echo "Create a new clusterrolebinding with cluster administration permissions and bind it to the service account"
  kubectl create clusterrolebinding add-on-cluster-admin --clusterrole=cluster-admin --serviceaccount=kube-system:kubeconfig-sa
  echo "Obtain the name of the service account authentication token and assign its value to an environment variable"
  TOKENNAME=`kubectl -n kube-system get serviceaccount/kubeconfig-sa -o jsonpath='{.secrets[0].name}'`
  echo "Obtain the value of the service account authentication token and assign its value (decoded from base64) to an environment variable"
  TOKEN=`kubectl -n kube-system get secret $TOKENNAME -o jsonpath='{.data.token}'| base64 --decode`
  echo "Add the service account (and its authentication token) as a new user definition in the kubeconfig file by entering"
  kubectl config set-credentials kubeconfig-sa --token=$TOKEN

  exit 0
}
main "$@"
