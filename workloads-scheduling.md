# Workloads & Scheduling (15%)

## Understand deployments and how to perform rolling update and rollbacks

Doc: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/

Questions:
- Create a deployment named `nginx-deploy` in the `ngx` namespace using nginx image version 1.19 with three replicas. Check that the deployment rolled out and show running pods.

<details><summary>Solution</summary>
<p>

```bash
# Create the template from kubectl
kubectl -n ngx create deployment nginx-deploy --replicas=3 --image=nginx:1.19 --dry-run=client -o yaml > nginx-deploy.yaml

# Create the namespace first
kubectl create ns ngx
kubectl apply -f nginx-deploy.yaml
```

Check that the deployment has rolled out and that it is running:

```bash
kubectl -n ngx rollout status deployment/nginx-deploy
deployment "nginx-deploy" successfully rolled out

kubectl -n ngx get deploy
NAME           READY   UP-TO-DATE   AVAILABLE   AGE
nginx-deploy   3/3     3            3           44s
```

Check the pods from the deployment:

```bash
kubectl -n ngx get pods
NAME                            READY   STATUS    RESTARTS   AGE
nginx-deploy-57767fb8cf-fjtls   1/1     Running   0          29s
nginx-deploy-57767fb8cf-krp4m   1/1     Running   0          29s
nginx-deploy-57767fb8cf-xvz8l   1/1     Running   0          29s
```

</p>
</details>

Questions:
- Scale the deployment to 5 replicas and check the status again.
- Then change the image tag of nginx container from 1.19 to 1.20.

<details><summary>Solution</summary>
<p>

```bash
kubectl -n ngx scale deployment nginx-deploy --replicas=5

kubectl -n ngx rollout status deployment nginx-deploy
deployment "nginx-deploy" successfully rolled out

kubectl -n ngx get deploy
NAME           READY   UP-TO-DATE   AVAILABLE   AGE
nginx-deploy   5/5     5            5           73s

kubectl -n ngx get pods
NAME                            READY   STATUS    RESTARTS   AGE
nginx-deploy-57767fb8cf-fjtls   1/1     Running   0          89s
nginx-deploy-57767fb8cf-krp4m   1/1     Running   0          89s
nginx-deploy-57767fb8cf-rlvwt   1/1     Running   0          26s
nginx-deploy-57767fb8cf-wdxt7   1/1     Running   0          26s
nginx-deploy-57767fb8cf-xvz8l   1/1     Running   0          89s
```

Change the image tag to 1.20:

```bash
kubectl -n ngx edit deployment/nginx-deploy
...
    spec:
      containers:
      - image: nginx:1.20
        imagePullPolicy: IfNotPresent
...
```

Check that new replicaset was created and new pods were deployed:

```bash
kubectl -n ngx get replicaset
NAME                      DESIRED   CURRENT   READY   AGE
nginx-deploy-57767fb8cf   0         0         0       2m54s
nginx-deploy-7bbd8545f9   5         5         5       17s

kubectl -n ngx get pods
NAME                            READY   STATUS    RESTARTS   AGE
nginx-deploy-7bbd8545f9-588mj   1/1     Running   0          30s
nginx-deploy-7bbd8545f9-djql7   1/1     Running   0          30s
nginx-deploy-7bbd8545f9-l77vm   1/1     Running   0          24s
nginx-deploy-7bbd8545f9-p46lm   1/1     Running   0          30s
nginx-deploy-7bbd8545f9-sxn4d   1/1     Running   0          22s
```

</p>
</details>

Questions:
- Check the history of the deployment and rollback to previous revision.
- Then check that the nginx image was reverted to 1.19.

<details><summary>Solution</summary>
<p>

```bash
kubectl -n ngx rollout history deployment nginx-deploy
kubectl -n ngx rollout undo deployment nginx-deploy
deployment.apps/nginx-deploy rolled back

kubectl -n ngx get replicaset
NAME                      DESIRED   CURRENT   READY   AGE
nginx-deploy-57767fb8cf   5         5         5       3m53s
nginx-deploy-7bbd8545f9   0         0         0       76s

kubectl -n ngx get pods
NAME                            READY   STATUS    RESTARTS   AGE
nginx-deploy-57767fb8cf-6mxpd   1/1     Running   0          29s
nginx-deploy-57767fb8cf-7xwls   1/1     Running   0          28s
nginx-deploy-57767fb8cf-dzbkr   1/1     Running   0          28s
nginx-deploy-57767fb8cf-tw7pr   1/1     Running   0          29s
nginx-deploy-57767fb8cf-zklv4   1/1     Running   0          29s

kubectl -n ngx get pods nginx-deploy-57767fb8cf-zklv4 -o jsonpath='{.spec.containers[0].image}'
nginx:1.19

```
</p>
</details>

## Use ConfigMaps and Secrets to configure applications

### Environment variables

Doc: https://kubernetes.io/docs/tasks/inject-data-application/define-environment-variable-container/

Questions:
- Create a pod with the latest busybox image running a sleep for 1 hour, and give it an environment variable named `PLANET` with the value `blue`.
- Then exec a command in the container to show that it has the configured environment variable.

<details><summary>Solution</summary>
<p>

The pod yaml `envvar.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  labels:
    run: envvar
  name: envvar
spec:
  containers:
  - image: busybox:latest
    name: envvar
    args:
      - sleep
      - "3600"
    env:
      - name: PLANET
        value: "blue"
```

Run and check:

```bash
# Run the pod:
kubectl apply -f envvar.yaml

# Check the env variable:
kubectl exec envvar -- env | grep PLANET
PLANET=blue
```

</p>
</details>

### ConfigMaps

Doc: https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/

Questions:
- Create a configmap named `space` with two values `planet=blue` and `moon=white`.
- Create a pod similar to the previous where you have two environment variables taken from the above configmap and show them in the container.

<details><summary>Solution</summary>
<p>

The configmap:
```bash
kubectl create configmap space --from-literal=planet=blue --from-literal=moon=white
configmap/space created
```

The pod yaml `configenvvar.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  labels:
    run: configenvvar
  name: configenvvar
spec:
  containers:
  - image: busybox:latest
    name: configenvvar
    args:
      - sleep
      - "3600"
    env:
      - name: PLANET
        valueFrom:
          configMapKeyRef:
            name: space
            key: planet
      - name: MOON
        valueFrom:
         configMapKeyRef:
            name: space
            key: moon
```

Create pod and show variables:

```bash
kubectl apply -f configenvvar.yaml
kubectl exec configenvvar -- env | grep -E "PLANET|MOON"
PLANET=blue
MOON=white
```

</p>
</details>

Questions:
- Create a configmap named `space-system` that contains a file named `system.conf` with the values `planet=blue` and `moon=white`.
- Mount the configmap to a pod and display it from the container through the path `/etc/system.conf`

<details><summary>Solution</summary>
<p>

```bash
cat << EOF > system.conf
planet=blue
moon=white
EOF

kubectl create configmap space-system --from-file=system.conf
```

The pod yaml `confvolume.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  labels:
    run: confvolume
  name: confvolume
spec:
  containers:
  - image: busybox:latest
    name: confvolume
    args:
      - sleep
      - "3600"
    volumeMounts:
      - name: system
        mountPath: /etc/system.conf
        subPath: system.conf
    resources: {}
  volumes:
  - name: system
    configMap:
      name: space-system
```

Create pod and show file:

```bash
kubectl apply -f confvolume.yaml

kubectl exec confvolume -- cat /etc/system.conf
planet=blue
moon=white
```

</p>
</details>

### Secrets

Doc: https://kubernetes.io/docs/concepts/configuration/secret/

Questions:
- Create a secret from files containing a username and a password.
- Use the secrets to define environment variables and display them.
- Mount the secret to a pod to `admin-cred` folder and display it.

<details><summary>Solution</summary>
<p>

Create secret.

```bash
echo -n 'admin' > username
echo -n 'admin-pass' > password

kubectl create secret generic admin-cred --from-file=username --from-file=password
```

Use secret as environment variables.

secretenv.yaml:
```yaml
apiVersion: v1
kind: Pod
metadata:
  labels:
    run: secretenv
  name: secretenv
spec:
  containers:
  - image: busybox:latest
    name: secretenv
    args:
      - sleep
      - "3600"
    env:
      - name: USERNAME
        valueFrom:
          secretKeyRef:
            name: admin-cred
            key: username
      - name: PASSWORD
        valueFrom:
          secretKeyRef:
            name: admin-cred
            key: password

```

```bash
kubectl apply -f secretenv.yaml

kubectl exec secretenv -- env | grep -E "USERNAME|PASSWORD"
USERNAME=admin
PASSWORD=admin-pass
```

Mount a secret to pod as a volume.

secretvolume.yaml:
```yaml
apiVersion: v1
kind: Pod
metadata:
  labels:
    run: secretvolume
  name: secretvolume
spec:
  containers:
  - image: busybox:latest
    name: secretvolume
    args:
      - sleep
      - "3600"
    volumeMounts:
      - name: admincred
        mountPath: /etc/admin-cred
        readOnly: true
  volumes:
  - name: admincred
    secret:
      secretName: admin-cred

```

```bash
kubectl apply -f secretvolume.yaml

kubectl exec secretvolume -- ls /etc/admin-cred
password
username

kubectl exec secretvolume -- cat /etc/admin-cred/username
admin

kubectl exec secretvolume -- cat /etc/admin-cred/password
admin-pass
```

</p>
</details>

## Know how to scale applications

Docs:
- https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
- https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/

Questions:
- Create a deployment with the latest nginx image and scale the deployment to 4 replicas.

<details><summary>Solution</summary>
<p>

```bash
kubectl create deployment scalable --image=nginx:latest
kubectl scale deployment scalable --replicas=4
kubectl get pods
NAME                        READY   STATUS    RESTARTS   AGE
scalable-6bbdb8895b-2fp5k   1/1     Running   0          6s
scalable-6bbdb8895b-2lww8   1/1     Running   0          6s
scalable-6bbdb8895b-l6ctd   1/1     Running   0          16s
scalable-6bbdb8895b-rh8cz   1/1     Running   0          6s
```

</p>
</details>

Questions:
- Autoscale a deployment to have a minimum of two pods and a maximum of 6 pods and that transitions when cpu usage goes above 70%.

<details><summary>Solution</summary>
<p>

In order to use Horizontal Pod Autoscaling, you need to have the metrics server installed in you cluster.

```bash
# Install metrics server
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Autoscale a deployment
kubectl create deployment autoscalable --image=nginx:latest
kubectl autoscale deployment autoscalable --min=2 --max=6 --cpu-percent=70
kubectl get hpa
kubectl get pods
NAME                            READY   STATUS    RESTARTS   AGE
autoscalable-6cdbc9b4c9-2c4kh   1/1     Running   0          28s
autoscalable-6cdbc9b4c9-2vdqj   1/1     Running   0          6s
```

</p>
</details>

## Understand the primitives used to create robust, self-healing, application deployments

Docs:
- https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
- https://kubernetes.io/docs/concepts/workloads/controllers/replicaset/

<details><summary>Solution</summary>
<p>

A deployment uses a replicaset object to maintain the right number of desired replicas of a pod.
See section "Understand Deployments and how to perform rolling updates and rollbacks" above to see how deployments handle replicaset for updating.

</p>
</details>

### Understand the role of DaemonSets

Doc: https://kubernetes.io/docs/concepts/workloads/controllers/daemonset/

Questions:
- Create a DaemonSet with the latest busybox image and see that it runs on all nodes.

<details><summary>Solution</summary>
<p>

daemonset.yaml
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
kubectl apply -f daemonset.yaml

kubectl get pods -o wide
NAME               READY   STATUS    RESTARTS   AGE   IP            NODE         NOMINATED NODE   READINESS GATES
daemontest-qc6sb   1/1     Running   0          14s   10.244.2.22   k8s-node-2   <none>           <none>
daemontest-st9wn   1/1     Running   0          14s   10.244.1.23   k8s-node-1   <none>           <none>
```

If you want the daemonset to run on the controlplane node, it needs to tolerate the controlnode taints, for example node-role.kubernetes.io/master:NoSchedule.

</p>
</details>

## Understand how to resource limits can affect Pod scheduling

Doc: https://kubernetes.io/docs/concepts/policy/resource-quotas/

Questions:
- Create a pod with a busybox container that requests 1G of memory and half a CPU, and has limits at 2G of memory and a whole CPU.

<details><summary>Solution</summary>
<p>

podquota.yaml
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
kubectl apply -f podquota.yaml

kubectl describe pod podquota
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

### Use label selectors to schedule Pods

Doc: https://kubernetes.io/docs/concepts/configuration/assign-pod-node/

Questions:
- Label a node with `kind=special` and schedule a pod to that node.

<details><summary>Solution</summary>
<p>

pod-selector.yaml:
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
kubectl label nodes k8s-node-1 kind=special
kubectl apply -f pod-selector.yaml

kubectl get pods -o wide
NAME     READY   STATUS    RESTARTS   AGE   IP            NODE         NOMINATED NODE   READINESS GATES
podsel   1/1     Running   0          4s    10.244.1.24   k8s-node-1   <none>           <none>

```

</p>
</details>

Questions:
- Use antiaffinity to launch a pod to a different node than the pod where the first one was scheduled.

<details><summary>Solution</summary>
<p>

pod-antiaffinity.yaml:
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
kubectl apply -f pod-antiaffinity.yaml

kubectl get pods -o wide
NAME     READY   STATUS    RESTARTS   AGE    IP            NODE         NOMINATED NODE   READINESS GATES
podaff   1/1     Running   0          7s     10.244.2.24   k8s-node-2   <none>           <none>
podsel   1/1     Running   0          2m3s   10.244.1.24   k8s-node-1   <none>           <none>

```

</p>
</details>

Questions:
- Taint a node with `type=special:NoSchedule`, make the other node unschedulable, and create a pod to tolerate this taint.

<details><summary>Solution</summary>
<p>

pod-toleration.yaml:
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
kubectl taint node k8s-node-1 type=special:NoSchedule
kubectl cordon k8s-node-2 #to force the scheduler to choose k8s-node-1
kubectl apply -f pod-toleration.yaml

kubectl get pods -o wide
NAME     READY   STATUS    RESTARTS   AGE   IP            NODE         NOMINATED NODE   READINESS GATES
podtol   1/1     Running   0          6s    10.244.1.26   k8s-node-1   <none>           <none>

# uncordon and remove taint
kubectl uncordon k8s-node-2
kubectl taint node k8s-node-1 type=special:NoSchedule- 
```

</p>
</details>

### Understand how to run multiple schedulers and how to configure Pods to use them

Doc: https://kubernetes.io/docs/tasks/extend-kubernetes/configure-multiple-schedulers/

### Manually schedule a Pod without a scheduler

Doc: https://kubernetes.io/docs/concepts/configuration/assign-pod-node/#nodename

Questions:
- Force a pod to be on a specific node with using the scheduler, and show that it was assigned to it.

<details><summary>Solution</summary>
<p>

pod-node.yaml:
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
  nodeName: k8s-node-2
```

```bash
kubectl apply -f pod-node.yaml

kubectl get pods -o wide
NAME      READY   STATUS    RESTARTS   AGE   IP            NODE         NOMINATED NODE   READINESS GATES
podnode   1/1     Running   0          14s   10.244.2.25   k8s-node-2   <none>           <none>
```

</p>
</details>

### Display scheduler events

Doc: https://kubernetes.io/docs/tasks/extend-kubernetes/configure-multiple-schedulers/#verifying-that-the-pods-were-scheduled-using-the-desired-schedulers

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

### Know how to configure the Kubernetes scheduler

Doc: https://kubernetes.io/docs/concepts/scheduling/scheduler-perf-tuning/

## Awareness of manifest management and common templating tools

You can use either Helm or Kustomize to make Kubernetes templates:
- Helm: https://helm.sh/docs/intro/quickstart/
- Kustomize: https://kubernetes.io/docs/tasks/manage-kubernetes-objects/kustomization/
