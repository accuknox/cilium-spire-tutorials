#!/bin/bash
kubectl delete pods client 2>/dev/null
kubectl delete -f 4-tls-upgrade.yaml 2> /dev/null
