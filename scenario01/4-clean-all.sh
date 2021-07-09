#!/bin/bash
kubectl delete pods poddefault podfoo 2>/dev/null
kubectl delete -f 2-deny-all.yaml 2> /dev/null
kubectl delete -f 3-spiffe-based.yaml 2> /dev/null
