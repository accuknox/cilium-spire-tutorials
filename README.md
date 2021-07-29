This tutorial shows some scenarios related to the Cilium and Spire integration.
The image below represents the summary of the actions performed in each of them.

<img src="imgs/background.png" alt="drawing" width="800"/>

## First steps

Download repository dependencies:

```
go vendor
```

Create minikube cluster:

```
minikube start --network-plugin=cni --memory=4096
minikube ssh -- sudo mount bpffs -t bpf /sys/fs/bpf
```

Deploy manifest (cilium + spire + dependencies):

```
kubectl apply -f cilium-spire.yaml
```

Check pods status:

```
kubectl get pods -A
NAMESPACE     NAME                               READY   STATUS    RESTARTS   AGE
kube-system   cilium-74m7n                       1/1     Running   0          47s
kube-system   cilium-operator-7c755f4594-2pk77   1/1     Running   0          3m25s
kube-system   cilium-operator-b76f5d644-ccmtc    0/1     Pending   0          51s
kube-system   cilium-operator-b76f5d644-mc5jn    0/1     Pending   0          51s
kube-system   coredns-74ff55c5b-l4jnn            1/1     Running   1          25h
kube-system   etcd-minikube                      1/1     Running   1          25h
kube-system   kube-apiserver-minikube            1/1     Running   1          25h
kube-system   kube-controller-manager-minikube   1/1     Running   1          25h
kube-system   kube-proxy-mggjl                   1/1     Running   1          25h
kube-system   kube-scheduler-minikube            1/1     Running   1          25h
kube-system   storage-provisioner                1/1     Running   2          25h
spire         spire-agent-648qt                  1/1     Running   0          47s
spire         spire-server-0                     1/1     Running   1          23h
```


## Tutorials

- [Scenario 1: L3/L4 policies based on SPIFFE ID](scenario01/README.md)  
- [Scenario 2: Authorizing with non-k8s workload (Server)](scenario02/)  
- [Scenario 3: Upgrading non-secure connections to mTLS](scenario03/README.md)  
- [Scenario 4: Upgrading non-secure connections to mTLS with multiple peerIDs (client)](scenario04/)
- [Scenario 5: Authorizing with non-k8s workload (Client)](scenario05/)  

## References

- [Accuknox Demo](https://docs.google.com/presentation/d/1LnjIQT7tTrk7V7zK8xPE4LW-R5lJbAAPvDVEvPU6_xA/edit) 