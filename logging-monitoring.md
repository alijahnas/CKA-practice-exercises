# Logging/Monitoring (5%)

## Understand how to monitor all cluster components

Doc: https://kubernetes.io/docs/tasks/debug-application-cluster/resource-metrics-pipeline/

Questions:
- Install the metrics server and show metrics for nodes and for pods in `kube-system` namespace.

<details><summary>Solution</summary>
<p>

```bash
git clone https://github.com/kubernetes-sigs/metrics-server
# Add --kubelet-insecure-tls to metrics-server/deploy/kubernetes/metrics-server-deployment.yaml if necessary
...
      containers:
      - name: metrics-server
        image: k8s.gcr.io/metrics-server-amd64:v0.3.6
        imagePullPolicy: IfNotPresent
        args:
          - --cert-dir=/tmp
          - --secure-port=4443
          - --kubelet-insecure-tls
...

# Launch the metrics server
kubectl apply -f kubectl apply -f metrics-server/deploy/kubernetes/

# Wait for the server to get metrics and show them
kubectl top nodes
NAME           CPU(cores)   CPU%   MEMORY(bytes)   MEMORY%
k8s-master     276m         13%    754Mi           19%
k8s-worker-1   87m          4%     391Mi           20%
k8s-worker-2   130m         6%     519Mi           27%

kubectl top pods -n kube-system
NAME                                 CPU(cores)   MEMORY(bytes)
coredns-66bff467f8-vr7ws             5m           5Mi
coredns-66bff467f8-w89dn             6m           6Mi
etcd-k8s-master                      44m          34Mi
kube-apiserver-k8s-master            78m          239Mi
kube-controller-manager-k8s-master   31m          37Mi
kube-flannel-ds-amd64-jgvg6          5m           9Mi
kube-flannel-ds-amd64-mdp7q          6m           9Mi
kube-flannel-ds-amd64-n9bfw          6m           9Mi
kube-proxy-f5c9j                     3m           12Mi
kube-proxy-qqhkq                     1m           12Mi
kube-proxy-tlmvq                     2m           12Mi
kube-scheduler-k8s-master            7m           10Mi
metrics-server-64b57fd654-zjcj9      1m           11Mi

```

</p>
</details>


## Understand how to monitor applications

Doc: https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/

Questions:
- Create an nginx pod with a liveness and a readiness probe for the port 80.

<details><summary>Solution</summary>
<p>

pod-ness.yml:
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
kubectl apply -f pod-ness.yml
kubectl describe pods nginx
...
    Liveness:       http-get http://:80/ delay=0s timeout=1s period=10s #success=1 #failure=3
    Readiness:      http-get http://:80/ delay=5s timeout=1s period=5s #success=1 #failure=3
...

```

</p>
</details>

## Manage cluster component logs

Questions:
- Get cluster components logs.

<details><summary>Solution</summary>
<p>

Logs depend on how your cluster was deployed.

For our deployment done in [Installation, Configuration & Validation 12%](https://github.com/alijahnas/CKA-practice-exercises/blob/master/installation-configuration-validation.md) here is how to get logs.

```bash
# Kubelet
sudo journalctl -u kubelet

# API server
kubectl -n kube-system logs kube-apiserver-k8s-master

# Controller Manager
kubectl -n kube-system logs kube-controller-manager-k8s-master

# Scheduler
kubectl -n kube-system logs kube-scheduler-k8s-master

```

</p>
</details>


## Manage application logs

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
