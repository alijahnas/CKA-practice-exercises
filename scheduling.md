# Scheduling (5%)

## Use label selectors to schedule Pods

Doc: https://kubernetes.io/docs/concepts/configuration/assign-pod-node/

Questions:
- Label a node with `kind=special` and schedule a pod to that node.

<details><summary>Solution</summary>
<p>

pod-selector.yml:
```yaml
apiVersion: v1
kind: Pod
metadata:
  labels:
    run: podsel
  name: podsel
spec:
  containers:
  - image: busybox:latest
    name: podsel
    args:
      - sleep
      - "3600"
  nodeSelector:
    kind: special
```

```bash
kubectl label nodes k8s-worker-1 kind=special
kubectl apply -f pod-selector.yml

kubectl get pods -o wide
NAME     READY   STATUS    RESTARTS   AGE   IP           NODE           NOMINATED NODE   READINESS GATES
podsel   1/1     Running   0          14s   10.244.1.6   k8s-worker-1   <none>           <none>

```

</p>
</details>

Questions:
- Use antiaffinity to launch a pod to a different node than the pod where the first one was scheduled.

<details><summary>Solution</summary>
<p>

pod-antiaffinity.yml:
```yaml
apiVersion: v1
kind: Pod
metadata:
  labels:
    run: podaff
  name: podaff
spec:
  containers:
  - image: busybox:latest
    name: podaff
    args:
      - sleep
      - "3600"
  affinity:
    podAntiAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        - labelSelector:
            matchExpressions:
              - key: run
                operator: In
                values:
                  - podsel
          topologyKey: kubernetes.io/hostname
```

```bash
kubectl apply -f pod-antiaffinity.yml

kubectl get pods -o wide
NAME     READY   STATUS    RESTARTS   AGE     IP            NODE           NOMINATED NODE   READINESS GATES
podaff   1/1     Running   0          8m47s   10.244.2.57   k8s-worker-2   <none>           <none>
podsel   1/1     Running   0          16m     10.244.1.8    k8s-worker-1   <none>           <none>

```

</p>
</details>

Questions:
- Taint a node with `type=special:NoSchedule`, make the other node unschedulable, and create a pod to tolerate this taint.

<details><summary>Solution</summary>
<p>

pod-toleration.yml:
```yaml
apiVersion: v1
kind: Pod
metadata:
  labels:
    run: podtol
  name: podtol
spec:
  containers:
  - image: busybox:latest
    name: podtol
    args:
      - sleep
      - "3600"
  tolerations:
  - key: "type"
    operator: "Equal"
    value: "special"
    effect: "NoSchedule"

```

```bash
kubectl taint node k8s-worker-1 type=special:NoSchedule
kubectl cordon k8s-worker-2
kubectl apply -f pod-toleration.yml

kubectl get pods -o wide
NAME     READY   STATUS    RESTARTS   AGE   IP            NODE           NOMINATED NODE   READINESS GATES
podtol   1/1     Running   0          16s   10.244.1.13   k8s-worker-1   <none>           <none>

```

</p>
</details>


## Understand the role of DaemonSets

Doc: https://kubernetes.io/docs/concepts/workloads/controllers/daemonset/

Questions:
- Create a DaemonSet and see that it runs on all nodes.

<details><summary>Solution</summary>
<p>

daemonset.yml
```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  labels:
    type: daemon
  name: daemontest
spec:
  selector:
    matchLabels:
      run: daemon
  template:
    metadata:
      labels:
        run: daemon
      name: daemonpod
    spec:
      containers:
      - image: busybox:latest
        name: daemonpod
        args:
          - sleep
          - "3600"
```

```bash
kubectl apply -f daemonset.yml

kubectl get pods -o wide
NAME               READY   STATUS    RESTARTS   AGE     IP            NODE           NOMINATED NODE   READINESS GATES
daemontest-9lwqc   1/1     Running   0          4m13s   10.244.1.14   k8s-worker-1   <none>           <none>
daemontest-ch7rq   1/1     Running   0          4m13s   10.244.2.65   k8s-worker-2   <none>           <none>

```

</p>
</details>


## Understand how resource limits can affect Pod Scheduling

Doc: https://kubernetes.io/docs/concepts/policy/resource-quotas/

Questions:
- Create a pod with a busybox container that requests 1G of memory and half a CPU, and has limits at 2G of memory and a whole CPU.

<details><summary>Solution</summary>
<p>

pod-quota.yml
```yaml
apiVersion: v1
kind: Pod
metadata:
  labels:
    run: podquota
  name: podquota
spec:
  containers:
  - image: busybox:latest
    name: podquota
    args:
      - sleep
      - "3600"
    resources:
      requests:
        memory: "1Gi"
        cpu: "500m"
      limits:
        memory: "2Gi"
        cpu: "1"

```

```bash
kubectl apply -f pod-quota.yml

kubectl describe pod pod-quota
...
    Limits:
      cpu:     1
      memory:  2Gi
    Requests:
      cpu:        500m
      memory:     1Gi
...
```

</p>
</details>


## Understand how to run multiple schedulers and how to configure Pods to use them

Doc: https://kubernetes.io/docs/tasks/administer-cluster/configure-multiple-schedulers/

## Manually schedule a Pod without a scheduler

Doc: https://kubernetes.io/docs/concepts/configuration/assign-pod-node/#nodename

Questions:
- Force a pod to be on a specific node with using the scheduler, and show that it was assigned to it.

<details><summary>Solution</summary>
<p>

pod-node.yml:
```yaml
apiVersion: v1
kind: Pod
metadata:
  labels:
    run: podnode
  name: podnode
spec:
  containers:
  - image: busybox:latest
    name: podnode
    args:
      - sleep
      - "3600"
  nodeName: k8s-worker-2

```

```bash
kubectl apply -f pod-node.yml

kubectl get pods -o wide
NAME       READY   STATUS    RESTARTS   AGE     IP            NODE           NOMINATED NODE   READINESS GATES
podnode    1/1     Running   0          10s     10.244.2.66   k8s-worker-2   <none>           <none>

```

</p>
</details>

## Display scheduler events

Doc: https://kubernetes.io/docs/tasks/administer-cluster/configure-multiple-schedulers/#verifying-that-the-pods-were-scheduled-using-the-desired-schedulers

Questions:
- Check the scheduler events.

<details><summary>Solution</summary>
<p>

```bash
kubectl get events
kubectl get events --all-namespaces
```

</p>
</details>

## Know how to configure the Kubernetes scheduler

Doc: https://kubernetes.io/docs/concepts/scheduling/scheduler-perf-tuning/
