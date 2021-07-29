## Scenario 3: Upgrading non-secure connections to mTLS

<img src="../imgs/scenario03.png" alt="drawing" width="800"/>

Create spire registration entries:

```
./0-create_registration_entries.sh
```

Deploy starwars pods (from cilium tutorials):

```
kubectl apply -f 1-http-sw-app.yaml
```

Check if the SPIFFE ID was assigned in `swing` and `deathstar` pods:

```
kubectl -n kube-system exec cilium-74m7n -- cilium endpoint list                                                                       
Defaulted container "cilium-agent" out of: cilium-agent, mount-cgroup (init), clean-cilium-state (init)                                                                                       
ENDPOINT   POLICY (ingress)   POLICY (egress)   IDENTITY   LABELS (source:key[=value])                                           IPv6       IPv4         STATUS                               
           ENFORCEMENT        ENFORCEMENT                                                                                                                                                     
100        Disabled           Disabled          4069       k8s:class=deathstar                                                   fd02::8e   10.0.0.176   ready                                
                                                           k8s:io.cilium.k8s.policy.cluster=default                                                                                           
                                                           k8s:io.cilium.k8s.policy.serviceaccount=starwars                                                                                   
                                                           k8s:io.kubernetes.pod.namespace=default                                                                                            
                                                           k8s:org=empire                                                                                                                     
                                                           spiffe://example.org/deathstar                                                                                                     
107        Disabled           Disabled          1          k8s:minikube.k8s.io/commit=0c397146a6e4f755686a1509562111cba05f46dd                           ready                                
                                                           k8s:minikube.k8s.io/name=minikube                                                                                                  
                                                           k8s:minikube.k8s.io/updated_at=2021_07_27T16_23_35_0700                                                                            
                                                           k8s:minikube.k8s.io/version=v1.21.0                                                                                                
                                                           k8s:node-role.kubernetes.io/control-plane                                                             
                                                           k8s:node-role.kubernetes.io/master                                                                     
                                                           reserved:host                                                                                          
732        Disabled           Disabled          4          reserved:health                                                       fd02::85   10.0.0.178   ready   
801        Disabled           Disabled          62228      k8s:class=xwing                                                       fd02::1c   10.0.0.115   ready   
                                                           k8s:io.cilium.k8s.policy.cluster=default                                                              
                                                           k8s:io.cilium.k8s.policy.serviceaccount=starwars                                                      
                                                           k8s:io.kubernetes.pod.namespace=default                                                               
                                                           k8s:org=alliance                                                                                       
                                                           spiffe://example.org/xwing                                                                             
871        Disabled           Disabled          26062      k8s:io.cilium.k8s.policy.cluster=default                                         10.0.0.72    ready   
                                                           k8s:io.cilium.k8s.policy.serviceaccount=coredns                                                       
                                                           k8s:io.kubernetes.pod.namespace=kube-system                                                           
                                                           k8s:k8s-app=kube-dns                                                                                   
3362       Disabled           Disabled          12147      k8s:app=spire-server                                                             10.0.0.140   ready   
                                                           k8s:io.cilium.k8s.policy.cluster=default                                                              
                                                           k8s:io.cilium.k8s.policy.serviceaccount=spire-server                                                  
                                                           k8s:io.kubernetes.pod.namespace=spire                                                                 
                                                           k8s:statefulset.kubernetes.io/pod-name=spire-server-0     
```
Now, we need to enforce a policy in order to upgrade the connection for the egress traffics from `swing` pod to port 80 and downgrade the connection for the ingress traffic to port 80 in `deathstar`.

```
apiVersion: "cilium.io/v2"
kind: CiliumNetworkPolicy
metadata:
  name: "tls-upgrade-xwing"
spec:
  endpointSelector:
    matchLabels:
      class: xwing
  egress:
  - toPorts:
    - ports:
      - port: "80"
        protocol: "TCP"
      originatingTLS:
        spiffe:
          peerIDs:
            - spiffe://example.org/deathstar
      rules:
        http:
        - {}
---
apiVersion: "cilium.io/v2"
kind: CiliumNetworkPolicy
metadata:
  name: "tls-upgrade-deathstar"
spec:
  endpointSelector:
    matchLabels:
      class: deathstar
  ingress:
  - toPorts:
    - ports:
      - port: "80"
        protocol: "TCP"
      terminatingTLS:
        spiffe:
          peerIDs:
            - spiffe://example.org/xwing
      rules:
        http:
        - {}
---
apiVersion: "cilium.io/v2"
kind: CiliumNetworkPolicy
metadata:
  name: "enable-xwing-dns"
spec:
  description: "Enable DNS traffic for xwing"
  endpointSelector:
    matchLabels:
     org: alliance
     class: xwing
  egress:
    - toPorts:
      - ports:
        - port: "53"
          protocol: UDP 
```

> The last policy is related to allow the DNS traffic for swing. It will be used later for HTTP request.

Apply Cilium Network Policies  (CNPs):

```
kubectl apply -f 2-mtls-upgrade.yaml
```

Check if the policies were enforced in `swing` and `deathstar` endpoints:

```
kubectl exec cilium-74m7n -- cilium endpoint list                                                                       
Defaulted container "cilium-agent" out of: cilium-agent, mount-cgroup (init), clean-cilium-state (init)                                                                                       
ENDPOINT   POLICY (ingress)   POLICY (egress)   IDENTITY   LABELS (source:key[=value])                                           IPv6       IPv4         STATUS                               
           ENFORCEMENT        ENFORCEMENT                                                                                                                                                     
100        Enabled            Disabled          4069       k8s:class=deathstar                                                   fd02::8e   10.0.0.176   ready                                
                                                           k8s:io.cilium.k8s.policy.cluster=default                                                                                           
                                                           k8s:io.cilium.k8s.policy.serviceaccount=starwars                                                                                   
                                                           k8s:io.kubernetes.pod.namespace=default                                                                                            
                                                           k8s:org=empire                                                                                                                     
                                                           spiffe://example.org/deathstar                                                                                                     
107        Disabled           Disabled          1          k8s:minikube.k8s.io/commit=0c397146a6e4f755686a1509562111cba05f46dd                           ready                                
                                                           k8s:minikube.k8s.io/name=minikube                                                                                                  
                                                           k8s:minikube.k8s.io/updated_at=2021_07_27T16_23_35_0700                                                                            
                                                           k8s:minikube.k8s.io/version=v1.21.0                                                                                                
                                                           k8s:node-role.kubernetes.io/control-plane                                                                                          
                                                           k8s:node-role.kubernetes.io/master                                                                                                 
                                                           reserved:host                                                                                                                      
732        Disabled           Disabled          4          reserved:health                                                       fd02::85   10.0.0.178   ready                                
801        Disabled           Enabled           62228      k8s:class=xwing                                                       fd02::1c   10.0.0.115   ready                                
                                                           k8s:io.cilium.k8s.policy.cluster=default                                                                                           
                                                           k8s:io.cilium.k8s.policy.serviceaccount=starwars                                                                                   
                                                           k8s:io.kubernetes.pod.namespace=default                                                                                            
                                                           k8s:org=alliance                                                                                                                   
                                                           spiffe://example.org/xwing                                                                                                         
871        Disabled           Disabled          26062      k8s:io.cilium.k8s.policy.cluster=default                                         10.0.0.72    ready                                
                                                           k8s:io.cilium.k8s.policy.serviceaccount=coredns                                                       
                                                           k8s:io.kubernetes.pod.namespace=kube-system                                                           
                                                           k8s:k8s-app=kube-dns                                                                                   
3362       Disabled           Disabled          12147      k8s:app=spire-server                                                             10.0.0.140   ready   
                                                           k8s:io.cilium.k8s.policy.cluster=default                                                              
                                                           k8s:io.cilium.k8s.policy.serviceaccount=spire-server                                                  
                                                           k8s:io.kubernetes.pod.namespace=spire                                                                 
                                                           k8s:statefulset.kubernetes.io/pod-name=spire-server-0  
```

Send landing request:

```
./4-curl.sh
```

The command `Ship landed` will be shown if the execution was succeeded:

Clean up the pods and CNPs:

```
./5-clean-all.sh
```