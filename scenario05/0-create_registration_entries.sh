#/bin/bash

# spire-agent
kubectl exec -n spire spire-server-0 -- \
    /opt/spire/bin/spire-server entry create \
    -node  \
    -spiffeID spiffe://example.org/ns/spire/sa/spire-agent \
    -selector k8s_sat:cluster:demo-cluster \
    -selector k8s_sat:agent_ns:spire \
    -selector k8s_sat:agent_sa:spire-agent

# cilium-agent
# This entry is needed to be sure that the cilium agent is able to use the spire
# privileged API. The unix:uid:0 selector is used because cilium-agent runs as a
# process in the host in the dev environment. If cilium-agent is run as a pod
# then the k8s selectors for that pod should be used.
kubectl exec -n spire spire-server-0 -- \
    /opt/spire/bin/spire-server entry create \
    -spiffeID spiffe://example.org/ciliumagent \
    -parentID spiffe://example.org/ns/spire/sa/spire-agent \
    -selector unix:uid:0

kubectl exec -n spire spire-server-0 -- \
    /opt/spire/bin/spire-server entry create \
    -spiffeID spiffe://example.org/client \
    -parentID spiffe://example.org/ns/spire/sa/spire-agent \
    -selector unix:uid:1002

kubectl exec -n spire spire-server-0 -- \
    /opt/spire/bin/spire-server entry create \
    -spiffeID spiffe://example.org/server \
    -parentID spiffe://example.org/ns/spire/sa/spire-agent \
    -selector k8s:sa:demo5 \
    -selector k8s:pod-name:server
