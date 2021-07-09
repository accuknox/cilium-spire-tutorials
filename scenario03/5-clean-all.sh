kubectl delete -f 1-http-sw-app.yaml 2> /dev/null
kubectl delete -f 2-mtls-upgrade.yaml 2> /dev/null
kubectl delete serviceaccount starwars 2> /dev/null
../spire-all-delete-entries.sh
