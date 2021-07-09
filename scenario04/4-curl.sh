#kubectl exec xwing -- curl -s  -XPOST http://$1:80/v1/request-landing
kubectl exec xwing -- curl -s  -XPOST http://deathstar.default.svc.cluster.local/v1/request-landing
kubectl exec xwing -- curl -s  -XPOST http://deathstar2.default.svc.cluster.local/v1/request-landing
