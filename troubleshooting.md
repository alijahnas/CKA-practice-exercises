# Troubleshooting (30%)

## Evaluate cluster and node logging

Questions:
- Get cluster components logs.

<details><summary>Solution</summary>
<p>

Logs depend on how your cluster was deployed.

For our deployment done in [Cluster Architecture, Installation & Configuration](https://github.com/alijahnas/CKA-practice-exercises/blob/CKA-v1.27/cluster-architecture-installation-configuration.md) here is how to get logs.

```bash
# Kubelet on all nodes
sudo journalctl -u kubelet

# API server
kubectl -n kube-system logs kube-apiserver-k8s-controlplane

# Controller Manager
kubectl -n kube-system logs kube-controller-manager-k8s-controlplane

# Scheduler
kubectl -n kube-system logs kube-scheduler-k8s-controlplane

```

</p>
</details>

## Understand how to monitor applications

Doc: https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/

Questions:
- Create an nginx pod with a liveness and a readiness probe for the port 80.

<details><summary>Solution</summary>
<p>

pod-ness.yaml:
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx
  labels:
    run: nginx
spec:
  containers:
  - name: nginx
    image: nginx:latest
    readinessProbe:
      httpGet:
        path: /
        port: 80
      initialDelaySeconds: 5
      periodSeconds: 5
    livenessProbe:
      httpGet:
        path: /
        port: 80
```

```bash
kubectl apply -f pod-ness.yaml
kubectl describe pods nginx
...
    Liveness:       http-get http://:80/ delay=0s timeout=1s period=10s #success=1 #failure=3
    Readiness:      http-get http://:80/ delay=5s timeout=1s period=5s #success=1 #failure=3
...

```

</p>
</details>

### Understand how to monitor all cluster components

Doc: https://kubernetes.io/docs/tasks/debug-application-cluster/resource-metrics-pipeline/

Questions:
- Install the metrics server and show metrics for nodes and for pods in `kube-system` namespace.

<details><summary>Solution</summary>
<p>

```bash
git clone https://github.com/kubernetes-sigs/metrics-server
# Add --kubelet-insecure-tls to metrics-server/manifests/base/deployment.yaml if necessary
...
      containers:
      - name: metrics-server
        image: gcr.io/k8s-staging-metrics-server/metrics-server:master
        imagePullPolicy: IfNotPresent
        args:
          - --cert-dir=/tmp
          - --secure-port=443
          - --kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname
          - --kubelet-use-node-status-port
          - --metric-resolution=15s
          - --kubelet-insecure-tls
...

# Deploy the metrics server
kubectl apply -k metrics-server/manifests/base/

# Wait for the server to get metrics and show them
kubectl top nodes
NAME               CPU(cores)   CPU%   MEMORY(bytes)   MEMORY%
k8s-controlplane   271m         13%    1075Mi          28%
k8s-node-1         115m         5%     636Mi           33%
k8s-node-2         97m          4%     564Mi           29%

kubectl top pods -n kube-system
NAME                                       CPU(cores)   MEMORY(bytes)
coredns-558bd4d5db-6cdkr                   6m           11Mi
coredns-558bd4d5db-k9qxs                   5m           19Mi
etcd-k8s-controlplane                      27m          71Mi
kube-apiserver-k8s-controlplane            112m         312Mi
kube-controller-manager-k8s-controlplane   34m          56Mi
kube-flannel-ds-nr5ms                      4m           11Mi
kube-flannel-ds-vl79c                      5m           13Mi
kube-flannel-ds-xvp8z                      7m           14Mi
kube-proxy-jjvc9                           2m           20Mi
kube-proxy-mwwnn                           1m           17Mi
kube-proxy-wr4v7                           1m           21Mi
kube-scheduler-k8s-controlplane            8m           18Mi
metrics-server-ffc48cc6c-g92v8             6m           16Mi
```

</p>
</details>

## Manage container stdout & stderr logs

Doc: https://kubernetes.io/docs/concepts/cluster-administration/logging/

Questions:
- Get logs from the nginx pod deployed earlier and redirect them to a file.

<details><summary>Solution</summary>
<p>

```bash
kubectl logs nginx > nginx.log
```

</p>
</details>

## Troubleshoot application failure

Doc: https://kubernetes.io/docs/tasks/debug-application-cluster/debug-application/

Questions:
- Launch a pod with a busybox container that launches with the `sheep 3600` command (this command doesn't exist.
- Get the logs from the pod, then correct the error to make it launch `sleep 3600`.

<details><summary>Solution</summary>
<p>

podfail.yaml:
```yaml
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
kubectl apply -f podfail.yaml

kubectl describe pods podfail
...
Warning  Failed     5s (x2 over 6s)  kubelet            Error: failed to create containerd task: OCI runtime create failed: container_linux.go:367: starting container process caused: exec: "sheep": executable file not found in $PATH: unknown
...

kubectl delete -f podfail.yaml
# Change sheep to sleep
kubectl apply -f podfail.yaml
...
Normal  Started    4s    kubelet            Started container podfail #Not failing anymore
...
```

</p>
</details>

## Troubleshoot cluster component failure

### Troubleshoot control plane failure

Doc: https://kubernetes.io/docs/tasks/debug-application-cluster/debug-cluster/

Questions:
- Get logs from the control plane in the `kube-system` namespace.

<details><summary>Solution</summary>
<p>

```bash
# API server
kubectl -n kube-system logs kube-apiserver-k8s-controlplane

# Controller Manager
kubectl -n kube-system logs kube-controller-manager-k8s-controlplane

# Scheduler
kubectl -n kube-system logs kube-scheduler-k8s-controlplane
```

</p>
</details>

### Troubleshoot worker node failure

Doc: https://kubernetes.io/docs/tasks/debug-application-cluster/debug-cluster/

Questions:
- Check the node status and the system logs for kubelet on the failing node.

<details><summary>Solution</summary>
<p>

```bash
kubectl describe node k8s-node-1

# From k8s-node-1 if reachable
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
                   kubernetes.io/name=CoreDNS
Annotations:       prometheus.io/port: 9153
                   prometheus.io/scrape: true
Selector:          k8s-app=kube-dns
Type:              ClusterIP
IP Family Policy:  SingleStack
IP Families:       IPv4
IP:                10.96.0.10
IPs:               10.96.0.10
Port:              dns  53/UDP
TargetPort:        53/UDP
Endpoints:         10.244.1.7:53,10.244.1.8:53
Port:              dns-tcp  53/TCP
TargetPort:        53/TCP
Endpoints:         10.244.1.7:53,10.244.1.8:53
Port:              metrics  9153/TCP
TargetPort:        9153/TCP
Endpoints:         10.244.1.7:9153,10.244.1.8:9153
Session Affinity:  None
Events:            <none>

kubectl -n kube-system describe ep kube-dns
Name:         kube-dns
Namespace:    kube-system
Labels:       k8s-app=kube-dns
              kubernetes.io/cluster-service=true
              kubernetes.io/name=CoreDNS
Annotations:  endpoints.kubernetes.io/last-change-trigger-time: 2021-05-19T08:39:25Z
Subsets:
  Addresses:          10.244.1.7,10.244.1.8
  NotReadyAddresses:  <none>
  Ports:
    Name     Port  Protocol
    ----     ----  --------
    dns-tcp  53    TCP
    dns      53    UDP
    metrics  9153  TCP

Events:  <none>

kubectl -n kube-system get pods -l k8s-app=kube-dns -o wide
NAME                       READY   STATUS    RESTARTS   AGE    IP           NODE         NOMINATED NODE   READINESS GATES
coredns-558bd4d5db-6cdkr   1/1     Running   1          5d3h   10.244.1.8   k8s-node-1   <none>           <none>
coredns-558bd4d5db-k9qxs   1/1     Running   1          5d3h   10.244.1.7   k8s-node-1   <none>           <none>
```

</p>
</details>
