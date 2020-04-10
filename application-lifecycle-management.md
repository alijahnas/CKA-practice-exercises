# Application Lifecycle Management (8%)

## Understand Deployments and how to perform rolling updates and rollbacks

Doc: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/

Questions:
- Create a deployment named `nginx-deploy` in the `ngx` namespace using nginx image version 1.16 with three replicas. Check that the deployment rolled out and show running pods.

<details><summary>Solution</summary>
<p>

```bash
# Create the template from kubectl
kubectl create deployment nginx-deploy --image=nginx:1.16 --dry-run=client -o yaml > nginx-deploy.yml

# Edit the template and add the namespace, and the replica number
emacs nginx-deploy.yml
```

The template should look like this:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  creationTimestamp: null
  labels:
    app: nginx
  name: nginx-deploy
  namespace: ngx
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  strategy: {}
  template:
    metadata:
      creationTimestamp: null
      labels:
        app: nginx
    spec:
      containers:
      - image: nginx:1.16
        name: nginx
        resources: {}
        status: {}
```

Apply the template:

```bash
# Create the namespace first
kubectl create ns ngx
kubectl apply -f nginx-deploy.yml
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
NAME                          READY   STATUS    RESTARTS   AGE
nginx-deploy-7ff78f74b9-8qqk2   1/1     Running   0          3m1s
nginx-deploy-7ff78f74b9-h9jcj   1/1     Running   0          3m1s
nginx-deploy-7ff78f74b9-nzhqz   1/1     Running   0          3m1s
```

</p>
</details>

Questions:
- Scale the deployment to 5 replicas and check the status again.
- Then change the image tag of nginx container from 1.16 to 1.17.

<details><summary>Solution</summary>
<p>

```bash
kubectl -n ngx scale deployment nginx-deploy --replicas=5

kubectl -n ngx rollout status deployment nginx-deploy
deployment "nginx-deploy" successfully rolled out

kubectl -n ngx get deploy
NAME           READY   UP-TO-DATE   AVAILABLE   AGE
nginx-deploy   5/5     5            5           5m32s

kubectl -n ngx get pods
NAME                          READY   STATUS    RESTARTS   AGE
nginx-deploy-7ff78f74b9-2mjcn   1/1     Running   0          71s
nginx-deploy-7ff78f74b9-8qqk2   1/1     Running   0          5m55s
nginx-deploy-7ff78f74b9-cpxrw   1/1     Running   0          71s
nginx-deploy-7ff78f74b9-h9jcj   1/1     Running   0          5m55s
nginx-deploy-7ff78f74b9-nzhqz   1/1     Running   0          5m55s

```

Change the image tag:

```bash
kubectl -n ngx edit deployment/nginx-deploy
...
    spec:
      containers:
      - image: nginx:1.17
        imagePullPolicy: IfNotPresent
...
```

Check that new replicaset was created and new pods were deployed:

```bash
kubectl -n ngx get replicaset
NAME                      DESIRED   CURRENT   READY   AGE
nginx-deploy-549f5fcb58   5         5         5       14m
nginx-deploy-7ff78f74b9   0         0         0       15m

kubectl -n ngx get pods
NAME                            READY   STATUS              RESTARTS   AGE
nginx-deploy-549f5fcb58-cpc2r   1/1     Running             0          15m
nginx-deploy-549f5fcb58-pg2lb   1/1     Running             0          15m
nginx-deploy-549f5fcb58-r9tvr   1/1     Running             0          15m
nginx-deploy-549f5fcb58-sjhjz   1/1     Running             0          15m
nginx-deploy-549f5fcb58-wdxqz   1/1     Running             0          15m

```

</p>
</details>

Questions:
- Check the history of the deployment and rollback to previous revision.
- Then check that the nginx image was reverted to 1.16.

<details><summary>Solution</summary>
<p>

```bash
kubectl -n ngx rollout history deployment nginx-deploy
kubectl -n ngx rollout undo deployment nginx-deploy

kubectl -n ngx get replicaset
NAME                      DESIRED   CURRENT   READY   AGE
nginx-deploy-549f5fcb58   0         0         0       30m
nginx-deploy-7ff78f74b9   5         5         5       30m

kubectl -n ngx get pods
NAME                            READY   STATUS    RESTARTS   AGE
nginx-deploy-7ff78f74b9-72xc8   1/1     Running   0          8m11s
nginx-deploy-7ff78f74b9-7c5wh   1/1     Running   0          8m9s
nginx-deploy-7ff78f74b9-fj5bg   1/1     Running   0          8m11s
nginx-deploy-7ff78f74b9-qcdkn   1/1     Running   0          8m11s
nginx-deploy-7ff78f74b9-xx8fm   1/1     Running   0          8m9s

kubectl -n ngx get pods nginx-deploy-7ff78f74b9-72xc8 -o jsonpath='{.spec.containers[0].image}'
nginx:1.16

```

</p>
</details>

## Know various ways to configure applications

### Environment variables

Doc: https://kubernetes.io/docs/tasks/inject-data-application/define-environment-variable-container/

Questions:
- Create a pod with the latest busybox image running a sleep for 1 hour, and give it an environment variable named `PLANET` with the value `blue`.
- Then exec a command in the container to show that it has the configured environment variable.

<details><summary>Solution</summary>
<p>

The pod yaml `envvar.yml`:

```yml
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
kubectl apply -f envvar.yml

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
```

The pod yaml `envvar.yml`:

```yml
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
kubectl apply -f envvar.yml
kubectl exec envvar -- env | grep -E "PLANET|MOON"
MOON=white
PLANET=blue
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

The pod yaml `confvolume.conf`:

```yaml
cat confvolume.yml
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
kubectl apply -f confvolume.yml

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
kubectl apply -f secretenv.yml

kubectl exec secretenv -- env | grep -E "USERNAME|PASSWORD"
USERNAME=admin
PASSWORD=admin-pass
```

Mount a secret to pod:

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
kubectl apply -f secretvolume.yml

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
scalable-5dd7b6d6f9-glrr5   1/1     Running   0          8s
scalable-5dd7b6d6f9-qt89g   1/1     Running   0          8s
scalable-5dd7b6d6f9-skc7f   1/1     Running   0          8s
scalable-5dd7b6d6f9-xzb5d   1/1     Running   0          25s

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
git clone https://github.com/kubernetes-sigs/metrics-server
kubectl apply -f metrics-server/deploy/kubernetes/

# Autoscale a deployment
kubectl create deployment autoscalable --image=nginx:latest
kubectl autoscale deployment autoscalable --min=2 --max=6 --cpu-percent=70
kubectl get hpa
kubectl get pods
NAME                            READY   STATUS    RESTARTS   AGE
autoscalable-6494b9665b-s8rrs   1/1     Running   0          8m16s
autoscalable-6494b9665b-vmdlt   1/1     Running   0          7m57s
```

</p>
</details>


## Understand the primitives necessary to create self-healing applications

Docs:
- https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
- https://kubernetes.io/docs/concepts/workloads/controllers/replicaset/

<details><summary>Solution</summary>
<p>

A deployment uses a replicaset object to maintain the right number of desired replicas of a pod.
See section "Understand Deployments and how to perform rolling updates and rollbacks" above to see how deployments handle replicaset for updating.

</p>
</details>

