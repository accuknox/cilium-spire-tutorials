#!/usr/bin/env bash
main() {

  set -o errexit
  set -o pipefail
  set -o nounset

  local -r __dirname="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  local -r __filename="${__dirname}/$(basename "${BASH_SOURCE[0]}")"

  date=$(date '+%Y-%m-%d-%H%M%S')
  for i in {1..30}; do
    ./1-deploy.sh  
    sleep 10s
    echo "======= $i times ========" >> logs-${date}-loop-entries.txt
    echo "sleep time: 10s" | tee -a logs-${date}-loop-entries.txt
    kubectl exec spire-server-0 -n spire -c spire-server --context cluster2 -- ./bin/spire-server entry show >> logs-${date}-loop-entries.txt
    echo "======= $i times ========" >> logs-${date}-registrar.txt
    echo "sleep time: 10s" | tee -a logs-${date}-registrar.txt
    kubectl -n spire logs pod/spire-server-0 >> logs-${date}-registrar.txt
    echo "======= $i times ========" >> logs-${date}-spire-server.txt
    echo "sleep time: 10s" | tee -a logs-${date}-spire-server.txt
    kubectl -n spire logs pod/spire-server-0 --context cluster2 >> logs-${date}-spire-server.txt
    echo "======= $i times ========" >> logs-${date}-spire-agent.txt
    echo "sleep time: 10s" | tee -a logs-${date}-spire-agent.txt
    kubectl -n spire logs pod/spire-server-0 --context cluster1 >> logs-${date}-spire-agent.txt
    
  done

  exit 0
}
main "$@"
