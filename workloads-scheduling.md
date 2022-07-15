# Workloads & Scheduling (15%)

## Understand deployments and how to perform rolling update and rollbacks

Doc: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/

Questions:
- Create a deployment named `nginx-deploy` in the `ns-nginx` namespace using nginx image version 1.22 with three replicas. Check that the deployment rolled out and show running pods.

<details><summary>Solution</summary>
<p>

```bash
# Create the template from kubectl
kubectl -n ns-nginx create deployment nginx-deploy --replicas=3 --image=nginx:1.22 --dry-run=client -o yaml > nginx-deploy.yaml

# Create the namespace first
kubectl create ns ns-nginx
kubectl apply -f nginx-deploy.yaml
```

Check that the deployment has rolled out and that it is running:

```bash
kubectl -n ns-nginx rollout status deployment/nginx-deploy
deployment "nginx-deploy" successfully rolled out

kubectl -n ns-nginx get deploy
NAME           READY   UP-TO-DATE   AVAILABLE   AGE
nginx-deploy   3/3     3            3           44s
```

Check the pods from the deployment:

```bash
kubectl -n ns-nginx get pods -o wide
NAME                            READY   STATUS    RESTARTS   AGE   IP           NODE         NOMINATED NODE   READINESS GATES
nginx-deploy-5c8bfcc47c-7wxl6   1/1     Running   0          18s   10.244.2.5   k8s-node-2   <none>           <none>
nginx-deploy-5c8bfcc47c-jc86s   1/1     Running   0          18s   10.244.1.7   k8s-node-1   <none>           <none>
nginx-deploy-5c8bfcc47c-lgwtg   1/1     Running   0          18s   10.244.1.6   k8s-node-1   <none>           <none>
```

</p>
</details>

Questions:
- Scale the deployment to 5 replicas and check the status again.
- Then change the image tag of nginx container from 1.22 to 1.23.

<details><summary>Solution</summary>
<p>

```bash
kubectl -n ns-nginx scale deployment nginx-deploy --replicas=5

kubectl -n ns-nginx rollout status deployment nginx-deploy
deployment "nginx-deploy" successfully rolled out

kubectl -n ns-nginx get deploy
NAME           READY   UP-TO-DATE   AVAILABLE   AGE
nginx-deploy   5/5     5            5           73s

kubectl -n ns-nginx get pods -o wide
NAME                            READY   STATUS    RESTARTS   AGE   IP           NODE         NOMINATED NODE   READINESS GATES
nginx-deploy-5c8bfcc47c-7wxl6   1/1     Running   0          91s   10.244.2.5   k8s-node-2   <none>           <none>
nginx-deploy-5c8bfcc47c-dfmp7   1/1     Running   0          15s   10.244.1.8   k8s-node-1   <none>           <none>
nginx-deploy-5c8bfcc47c-jc86s   1/1     Running   0          91s   10.244.1.7   k8s-node-1   <none>           <none>
nginx-deploy-5c8bfcc47c-jwrgg   1/1     Running   0          15s   10.244.2.6   k8s-node-2   <none>           <none>
nginx-deploy-5c8bfcc47c-lgwtg   1/1     Running   0          91s   10.244.1.6   k8s-node-1   <none>           <none>
```

Change the image tag to 1.23:

```bash
kubectl -n ns-nginx edit deployment/nginx-deploy
...
    spec:
      containers:
      - image: nginx:1.23
        imagePullPolicy: IfNotPresent
...
```

Check that new replicaset was created and new pods were deployed:

```bash
kubectl -n ns-nginx get replicaset
NAME                      DESIRED   CURRENT   READY   AGE
nginx-deploy-55679458fd   5         5         5       24s
nginx-deploy-5c8bfcc47c   0         0         0       2m31s

kubectl -n ns-nginx get pods -o wide
NAME                            READY   STATUS    RESTARTS   AGE   IP            NODE         NOMINATED NODE   READINESS GATES
nginx-deploy-55679458fd-bzxbj   1/1     Running   0          32s   10.244.1.10   k8s-node-1   <none>           <none>
nginx-deploy-55679458fd-fsgvt   1/1     Running   0          40s   10.244.2.7    k8s-node-2   <none>           <none>
nginx-deploy-55679458fd-htfqd   1/1     Running   0          30s   10.244.2.9    k8s-node-2   <none>           <none>
nginx-deploy-55679458fd-s4n7k   1/1     Running   0          40s   10.244.1.9    k8s-node-1   <none>           <none>
nginx-deploy-55679458fd-zknwp   1/1     Running   0          40s   10.244.2.8    k8s-node-2   <none>           <none>
```

</p>
</details>

Questions:
- Check the history of the deployment and rollback to previous revision.
- Then check that the nginx image was reverted to 1.22.

<details><summary>Solution</summary>
<p>

```bash
kubectl -n ns-nginx rollout history deployment nginx-deploy
kubectl -n ns-nginx rollout undo deployment nginx-deploy
deployment.apps/nginx-deploy rolled back

kubectl -n ns-nginx get replicaset
NAME                      DESIRED   CURRENT   READY   AGE
nginx-deploy-55679458fd   0         0         0       3m37s
nginx-deploy-5c8bfcc47c   5         5         5       5m44s

kubectl -n ns-nginx get pods -o wide
NAME                            READY   STATUS    RESTARTS   AGE   IP            NODE         NOMINATED NODE   READINESS GATES
nginx-deploy-5c8bfcc47c-8kfck   1/1     Running   0          43s   10.244.2.11   k8s-node-2   <none>           <none>
nginx-deploy-5c8bfcc47c-hqlxd   1/1     Running   0          44s   10.244.1.12   k8s-node-1   <none>           <none>
nginx-deploy-5c8bfcc47c-rb8gn   1/1     Running   0          44s   10.244.2.10   k8s-node-2   <none>           <none>
nginx-deploy-5c8bfcc47c-tjbcw   1/1     Running   0          43s   10.244.1.13   k8s-node-1   <none>           <none>
nginx-deploy-5c8bfcc47c-vvdfr   1/1     Running   0          44s   10.244.1.11   k8s-node-1   <none>           <none>

kubectl -n ns-nginx get pods nginx-deploy-57767fb8cf-zklv4 -o jsonpath='{.spec.containers[0].image}'
nginx:1.22

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

kubectl get deployment
NAME       READY   UP-TO-DATE   AVAILABLE   AGE
scalable   1/1     1            1           4s

kubectl scale deployment scalable --replicas=4

kubectl get deployment
NAME       READY   UP-TO-DATE   AVAILABLE   AGE
scalable   4/4     4            4           34s

kubectl get pods -o wide
NAME                       READY   STATUS    RESTARTS   AGE   IP            NODE         NOMINATED NODE   READINESS GATES
scalable-5447d459b-9d5bg   1/1     Running   0          28s   10.244.2.13   k8s-node-2   <none>           <none>
scalable-5447d459b-g5fmc   1/1     Running   0          28s   10.244.1.15   k8s-node-1   <none>           <none>
scalable-5447d459b-pwr7p   1/1     Running   0          28s   10.244.1.14   k8s-node-1   <none>           <none>
scalable-5447d459b-xhkhw   1/1     Running   0          58s   10.244.2.12   k8s-node-2   <none>           <none>
```

</p>
</details>

Questions:
- Autoscale a deployment to have a minimum of two pods and a maximum of 6 pods and that transitions when cpu usage goes above 70%.

<details><summary>Solution</summary>
<p>

In order to use Horizontal Pod Autoscaling, you need to have the metrics server installed in you cluster.

```bash
# Configure metrics server
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

# Autoscale a deployment
kubectl create deployment autoscalable --image=nginx:latest

kubectl get deploy
NAME           READY   UP-TO-DATE   AVAILABLE   AGE
autoscalable   1/1     1            1           14s

kubectl autoscale deployment autoscalable --min=2 --max=6 --cpu-percent=70
horizontalpodautoscaler.autoscaling/autoscalable autoscaled

kubectl get hpa
NAME           REFERENCE                 TARGETS         MINPODS   MAXPODS   REPLICAS   AGE
autoscalable   Deployment/autoscalable   <unknown>/70%   2         6         0          5s

kubectl get pods -o wide
NAME                            READY   STATUS    RESTARTS   AGE   IP            NODE         NOMINATED NODE   READINESS GATES
autoscalable-769846cf95-hlvd7   1/1     Running   0          23s   10.244.2.15   k8s-node-2   <none>           <none>
autoscalable-769846cf95-xxlmc   1/1     Running   0          76s   10.244.1.16   k8s-node-1   <none>           <none>
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

If you want the daemonset to run on the controlplane node, it needs to tolerate the controlnode taints, for example node-role.kubernetes.io/master:NoSchedule and node-role.kubernetes.io/control-plane:NoSchedule.

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
