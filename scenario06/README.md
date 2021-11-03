# Scenario 6: Auto-generating Cilium label (SPIFFE ID) using SPIRE K8s Workload Registrar

Description of the scenario: the goal of the scenario exposed by the image below is to use the SPIRE [k8s-workload-registrar](https://github.com/spiffe/spire/tree/main/support/k8s/k8s-workload-registrar) component to automatically assign the SPIFFE ID to a workload (nginx) and verify that the ID was created as a k8s label in Cilium. This label can be used in [Cilium Network Policies](https://docs.cilium.io/en/stable/concepts/kubernetes/policy/#ciliumnetworkpolicy)(CNPs) for policy enforcement . 

<img src="../imgs/scenario06.png" alt="drawing" width="800"/>

For this tutorial the following steps will be performed:
1. Deploy two minikube cluster;
1. Configure Service Accounts in cluster1 to access TokenReview API to be used by `spire-server` on cluster2
1. Deploy `spire-server` on cluster2
1. Insert registration entries for `cilium-agent` and `k8s-workload-registrar` in `spire-server`;
1. Deploy `spire-agent` + `cilium-agent` + `k8s-workload-registrar` + `nginx` on cluster1;
1. Check that `nginx` SPIFFE ID was automatically created;
1. Check that `nginx` SPIFFE ID was created as a k8s label in `cilium-agent`

## Software Requirements: 

Be sure that you have already installed: 

- minikube v1.21 + docker driver
- jq
- helm3

## Steps

> :memo: The following steps were tested with Manjaro and Ubuntu 20.04 Linux distributions. 

Create clusters:

```
./0-start-clusters.sh
```

Deploy the pods in cluster1 and cluster2:

```
./1-deploy.sh
```

Check if the registration entries were created in `spire-server`: 

```
kubectl exec spire-server-0 -n spire -c spire-server --context cluster2 -- ./bin/spire-server entry show  
```

The output should be: 

```
Found 4 entries
Entry ID         : fee71387-3b2d-4b64-9b9a-671b12387c8b
SPIFFE ID        : spiffe://example.org/ciliumagent
Parent ID        : spiffe://example.org/spire/agent/k8s_psat/demo-cluster/59092f2c-bb7f-424d-8110-fc6668beaf59
Revision         : 0
TTL              : default
Selector         : unix:uid:0
Admin            : true

Entry ID         : 1a08e0ad-564e-4c68-bf16-5d96342908af
SPIFFE ID        : spiffe://example.org/k8s-workload-registrar/demo-cluster/node/cluster1
Parent ID        : spiffe://example.org/spire/server
Revision         : 0
TTL              : default
Selector         : k8s_psat:agent_node_uid:59092f2c-bb7f-424d-8110-fc6668beaf59
Selector         : k8s_psat:cluster:demo-cluster

Entry ID         : fd7c4aeb-2724-48f2-98ac-419050f7e84f
SPIFFE ID        : spiffe://example.org/ns/default/sa/default
Parent ID        : spiffe://example.org/k8s-workload-registrar/demo-cluster/node/cluster1
Revision         : 0
TTL              : default
Selector         : k8s:node-name:cluster1
Selector         : k8s:ns:default
Selector         : k8s:pod-uid:917a0c14-f6a8-49fd-92d9-95001a2589a9
DNS name         : nginx-deployment-7ffbd8bd54-v2v5x

Entry ID         : 0070bf09-80af-4b74-95ba-913a1ad107e6
SPIFFE ID        : spiffe://example.org/registrar
Parent ID        : spiffe://example.org/spire/agent/k8s_psat/demo-cluster/59092f2c-bb7f-424d-8110-fc6668beaf59
Revision         : 0
TTL              : default
Selector         : k8s:pod-label:app:spire-server
Selector         : unix:uid:0
Admin            : true
```

Check if the `nginx` SPIFFE ID label were created in `cilium-agent`:

```
kubectl -n kube-system exec pod/$(kubectl -n kube-system get pod -l k8s-app=cilium -o jsonpath="{.items[0].metadata.name}") -- cilium endpoint list
```

The output should be:
```
Defaulted container "cilium-agent" out of: cilium-agent, mount-cgroup (init), clean-cilium-state (init)
ENDPOINT   POLICY (ingress)   POLICY (egress)   IDENTITY   LABELS (source:key[=value])                                           IPv6       IPv4         STATUS   
           ENFORCEMENT        ENFORCEMENT                                                                                                                
73         Disabled           Disabled          1          k8s:minikube.k8s.io/commit=76d74191d82c47883dc7e1319ef7cebd3e00ee11                           ready   
                                                           k8s:minikube.k8s.io/name=cluster1                                                                     
                                                           k8s:minikube.k8s.io/updated_at=2021_10_28T12_14_38_0700                                               
                                                           k8s:minikube.k8s.io/version=v1.21.0                                                                   
                                                           k8s:node-role.kubernetes.io/control-plane                                                             
                                                           k8s:node-role.kubernetes.io/master                                                                    
                                                           reserved:host                                                                                         
219        Disabled           Disabled          4          reserved:health                                                       fd02::7b   10.0.0.192   ready   
713        Disabled           Disabled          7528       k8s:io.cilium.k8s.policy.cluster=default                              fd02::3d   10.0.0.220   ready   
                                                           k8s:io.cilium.k8s.policy.serviceaccount=coredns                                                       
                                                           k8s:io.kubernetes.pod.namespace=kube-system                                                           
                                                           k8s:k8s-app=kube-dns                                                                                  
2431       Disabled           Disabled          26975      k8s:app=nginx                                                         fd02::fe   10.0.0.212   ready   
                                                           k8s:io.cilium.k8s.policy.cluster=default                                                              
                                                           k8s:io.cilium.k8s.policy.serviceaccount=default                                                       
                                                           k8s:io.kubernetes.pod.namespace=default                                                               
                                                           k8s:spiffe.io/spiffe-id=true                                                                          
                                                           spiffe://example.org/ns/default/sa/default  
```

As we can see, the SPIFFE ID `spiffe://example.org/ns/default/sa/default` was assigned to nginx pod as a k8s label.

Finally, to clean-up:

```
./3-delete-clusters.sh
```
