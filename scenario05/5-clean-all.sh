#!/bin/bash
kubectl delete -f 1-http-sw-app.yaml 2>/dev/null
kubectl delete -f 4-tls-upgrade-dst-port.yaml 2> /dev/null
