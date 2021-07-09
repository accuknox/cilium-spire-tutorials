Check this [presentation](https://docs.google.com/presentation/d/1LnjIQT7tTrk7V7zK8xPE4LW-R5lJbAAPvDVEvPU6_xA/edit) for more information.  

## First steps

- Download repository dependencies: `go vendor`
- Setup cilium development environment
- Checkout the branchs
	- cilium: kinvolk:mauricio/spiffe-integration-poc-part2 
	- cilium-proxy: kinvolk:mauricio/spiffe-integration-poc-part2 
- Compile and install `cilium` and `cilium-proxy` 
- Deploy `spire-agent` and `spire-server`: `kubectl -f spire.yaml`

## Tutorials

- [Scenario 1: L3/L4 policies based on SPIFFE ID](scenario01/)
- [Scenario 2: Authorizing with non-k8s workload (Server)](scenario02/)
- [Scenario 3: Upgrading non-secure connections to mTLS](scenario03/)
- [Scenario 4: Upgrading non-secure connections to mTLS with multiple peerIDs (client)](scenario04/)
- [Scenario 5: Authorizing with non-k8s workload (Client)](scenario05/)
