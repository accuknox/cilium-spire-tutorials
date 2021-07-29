## Scenario 1: L3/L4 policies based on SPIFFE ID

<img src="../imgs/scenario01.png" alt="drawing" width="800"/>

Create spire registration entries

```
./0-create-entries.sh
```

Deploy pods `poddefault` and `podfoo`. The former is deployed on namespace `default`. The other one is deployed on namespace `foo`.

```
kubectl apply -f 1-http-sw-app.yaml
```

Check if the SPIFFE ID was assigned in `swing` and `deathstar` pods:

```
kubectl -n kube-system exec cilium-74m7n -- cilium endpoint list
Defaulted container "cilium-agent" out of: cilium-agent, mount-cgroup (init), clean-cilium-state (init)
ENDPOINT   POLICY (ingress)   POLICY (egress)   IDENTITY   LABELS (source:key[=value])                                           IPv6       IPv4         STATUS   
           ENFORCEMENT        ENFORCEMENT                                                                                                                
107        Disabled           Disabled          1          k8s:minikube.k8s.io/commit=0c397146a6e4f755686a1509562111cba05f46dd                           ready   
                                                           k8s:minikube.k8s.io/name=minikube                                                                     
                                                           k8s:minikube.k8s.io/updated_at=2021_07_27T16_23_35_0700                                               
                                                           k8s:minikube.k8s.io/version=v1.21.0                                                                   
                                                           k8s:node-role.kubernetes.io/control-plane                                                             
                                                           k8s:node-role.kubernetes.io/master                                                                    
                                                           reserved:host                                                                                         
619        Disabled           Disabled          20802      k8s:io.cilium.k8s.policy.cluster=default                              fd02::7a   10.0.0.145   ready   
                                                           k8s:io.cilium.k8s.policy.serviceaccount=foo                                                           
                                                           k8s:io.kubernetes.pod.namespace=default                                                               
                                                           k8s:type=my-pod                                                                                       
                                                           spiffe://example.org/ns/default/sa/foo                                                                
732        Disabled           Disabled          4          reserved:health                                                       fd02::85   10.0.0.178   ready   
871        Disabled           Disabled          26062      k8s:io.cilium.k8s.policy.cluster=default                                         10.0.0.72    ready   
                                                           k8s:io.cilium.k8s.policy.serviceaccount=coredns                                                       
                                                           k8s:io.kubernetes.pod.namespace=kube-system                                                           
                                                           k8s:k8s-app=kube-dns                                                                                  
1194       Disabled           Disabled          26073      k8s:io.cilium.k8s.policy.cluster=default                              fd02::bc   10.0.0.13    ready   
                                                           k8s:io.cilium.k8s.policy.serviceaccount=default                                                       
                                                           k8s:io.kubernetes.pod.namespace=default                                                               
                                                           k8s:type=my-pod                                                                                       
                                                           spiffe://example.org/ns/default/sa/default                                                            
3362       Disabled           Disabled          12147      k8s:app=spire-server                                                             10.0.0.140   ready   
                                                           k8s:io.cilium.k8s.policy.cluster=default                                                              
                                                           k8s:io.cilium.k8s.policy.serviceaccount=spire-server                                                  
                                                           k8s:io.kubernetes.pod.namespace=spire                                                                 
                                                           k8s:statefulset.kubernetes.io/pod-name=spire-server-0     
```

Lets deny all the  communication only between them. 

```
kubectl apply -f 2-deny-all.yaml
```

Check the if the communication will be blocked between the endpoints:

```
kubectl exec poddefault -- ping <ip-podfoo>
```

> The podfoo IP address is found using the command `kubectl get pods poddefault -o wide`

Lets allow the communication from poddefault to podfoo. Note the policy below is based on the SPIFFE ID that were assigned in each endpoint.

```
# Allow pods running with the default service account to contact pods
# running with the foo service account.
apiVersion: "cilium.io/v2"
kind: CiliumNetworkPolicy
metadata:
  name: "spiffe-based"
spec:
  endpointSelector:
    matchLabels:
      spiffe://example.org/ns/default/sa/default: ""
  egress:
  - toEndpoints:
    - matchLabels:
        spiffe://example.org/ns/default/sa/foo: ""

```

Apply Cilium Network Policies (CNPs):

```
kubectl apply -f 3-spiffe-based.yaml
```

Let's check the if the communication is allowed between the endpoints with this new policy:

```
kubectl exec poddefault -- ping <ip-podfoo>
PING 10.0.0.84 (10.0.0.84) 56(84) bytes of data.
64 bytes from 10.0.0.84: icmp_seq=1 ttl=64 time=0.059 ms
64 bytes from 10.0.0.84: icmp_seq=2 ttl=64 time=0.054 ms
```

Great! The policy enforcement based on SPIFFE ID label is working.

To clean up the pods and CNPs:

```
./4-clean-all.sh
```