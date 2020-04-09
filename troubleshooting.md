# Troubleshooting (10%)

## Troubleshoot application failure

Doc: https://kubernetes.io/docs/tasks/debug-application-cluster/debug-application/

Questions:
- Launch a pod with a busybox container that launches with the `sheep 3600` command (this command doesn't exist.
- Get the logs from the pod, then correct the error to make it launch `sleep 3600`.

<details><summary>Solution</summary>
<p>

podfail.yml:
```yml
apiVersion: v1
kind: Pod
metadata:
  labels:
    run: podfail
  name: podfail
spec:
  containers:
  - image: busybox:latest
    name: podfail
	args:
	  - sheep
	  - "3600"
```

```bash
kubectl apply -f podfail.yml

kubectl describe pods podfail
...
Warning  Failed     3m14s (x4 over 4m2s)   kubelet, k8s-worker-1  Error: failed to start container "podfail": Error response from daemon: OCI runtime create failed: container_linux.go:346: starting container process caused "exec: \"sheep\": executable file not found in $PATH": unknown
...

kubectl delete -f podfail.yml
# Change sheep to sleep
kubectl apply -f podfail.yml
```

</p>
</details>


## Troubleshoot control plane failure

Doc: https://kubernetes.io/docs/tasks/debug-application-cluster/debug-cluster/

Questions:
- Get logs from the control plane in the `kube-system` namespace.

<details><summary>Solution</summary>
<p>

Check: https://github.com/alijahnas/CKA-practice-exercises/blob/master/logging-monitoring.md#manage-cluster-component-logs

</p>
</details>


## Troubleshoot worker node failure

Doc: https://kubernetes.io/docs/tasks/debug-application-cluster/debug-cluster/

Questions:
- Check the node status and the system logs for kubelet on the failing node.

<details><summary>Solution</summary>
<p>

```bash
kubectl describe node k8s-worker-1

# From k8s-worker-1 if reachable
sudo journalctl -u kubelet | grep -i error
```

</p>
</details>


## Troubleshoot networking

Doc: https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/

Questions:
- Check the `kube-dns` service running in the `kube-system` namespace and check the endpoints behind the service. Check the pods that serve the endpoints.

<details><summary>Solution</summary>
<p>

```bash
kubectl -n kube-system describe svc kube-dns
Name:              kube-dns
Namespace:         kube-system
Labels:            k8s-app=kube-dns
                   kubernetes.io/cluster-service=true
                   kubernetes.io/name=KubeDNS
Annotations:       prometheus.io/port: 9153
                   prometheus.io/scrape: true
Selector:          k8s-app=kube-dns
Type:              ClusterIP
IP:                10.96.0.10
Port:              dns  53/UDP
TargetPort:        53/UDP
Endpoints:         10.244.0.9:53,10.244.2.64:53
Port:              dns-tcp  53/TCP
TargetPort:        53/TCP
Endpoints:         10.244.0.9:53,10.244.2.64:53
Port:              metrics  9153/TCP
TargetPort:        9153/TCP
Endpoints:         10.244.0.9:9153,10.244.2.64:9153
Session Affinity:  None
Events:            <none>

kubectl -n kube-system describe ep kube-dns
Name:         kube-dns
Namespace:    kube-system
Labels:       k8s-app=kube-dns
              kubernetes.io/cluster-service=true
              kubernetes.io/name=KubeDNS
Annotations:  <none>
Subsets:
  Addresses:          10.244.0.9,10.244.2.64
  NotReadyAddresses:  <none>
  Ports:
    Name     Port  Protocol
    ----     ----  --------
    dns-tcp  53    TCP
    metrics  9153  TCP
    dns      53    UDP

Events:  <none>

kubectl -n kube-system get pods -l k8s-app=kube-dns -o wide
NAME                       READY   STATUS    RESTARTS   AGE    IP            NODE           NOMINATED NODE   READINESS GATES
coredns-66bff467f8-vr7ws   1/1     Running   1          3d5h   10.244.0.9    k8s-master     <none>           <none>
coredns-66bff467f8-w89dn   1/1     Running   1          3d5h   10.244.2.64   k8s-worker-2   <none>           <none>

```

</p>
</details>
