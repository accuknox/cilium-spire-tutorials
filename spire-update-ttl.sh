#!/bin/bash

if [[ $# -lt 2 ]] ; then
        echo "Script to change the ttl of given SPIFFE ID (works just for one entry of the SPIFFE ID)"
        echo "Usage: $0 \"spiffe://trust/workload\" ttl"
        exit 0
fi

echo "Change "$1" ttl to $2"
ENTRY_SELECTOR=`kubectl exec -n spire spire-server-0 -- /opt/spire/bin/spire-server entry show -spiffeID $1 | awk '/Selector/ {print $3}'`

ENTRY_ID=`kubectl exec -n spire spire-server-0 -- /opt/spire/bin/spire-server entry show -spiffeID "$1" | awk '/Entry ID/ {print $4}'`
ENTRY_PARENT_ID=`kubectl exec -n spire spire-server-0 -- /opt/spire/bin/spire-server entry show -spiffeID "$1" | awk '/Parent ID/ {print $4}'`

#echo $ENTRY_SELECTOR
#echo $ENTRY_ID
#echo $ENTRY_PARENT_ID
kubectl exec -n spire spire-server-0 -- /opt/spire/bin/spire-server entry update -entryID $ENTRY_ID  -parentID $ENTRY_PARENT_ID  -selector $ENTRY_SELECTOR -spiffeID $1 -ttl $2
