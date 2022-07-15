# Storage (10%)

## Understand storage classes, persistent volumes

Doc: https://kubernetes.io/docs/concepts/storage/storage-classes/
Doc: https://kubernetes.io/docs/concepts/storage/persistent-volumes/

## Understand volume mode, access modes and reclaim policies for volumes

Doc: https://kubernetes.io/docs/concepts/storage/persistent-volumes/#access-modes
Doc: https://kubernetes.io/docs/concepts/storage/persistent-volumes/#reclaiming
Doc: https://kubernetes.io/docs/concepts/storage/persistent-volumes/#volume-mode

## Understand persistent volume claims primitive

Doc: https://kubernetes.io/docs/tasks/administer-cluster/change-pv-reclaim-policy/

## Know how to configure applications with persistent storage

Doc: https://kubernetes.io/docs/concepts/storage/persistent-volumes/

Questions:
- Create a pod and mount a volume with hostPath directory.
- Check that the contents of the directory are accessible through the pod.

<details><summary>Solution</summary>
<p>

pv-pod.yaml:
```yaml
apiVersion: v1
kind: Pod
metadata:
  labels:
    run: pv-pod
  name: pv-pod
spec:
  containers:
  - image: busybox:latest
    name: pv-pod
    args:
      - sleep
      - "3600"
    volumeMounts:
    - name: data
      mountPath: "/data"
  volumes:
  - name: data
    hostPath:
      path: "/home/ubuntu/data/"
```

```bash
# Create directory and file inside it on worker nodes
mkdir /home/ubuntu/data
touch data/file

kubectl apply -f pv-pod.yaml
kubectl exec pv-pod -- ls /data
file
```

</p>
</details>

Questions:
- Create a persistent volume from hostPath and a persistent volume claim corresponding tothat PV. Create a pod that uses the PVC and check that the volume is mounted in the pod.
- Create a file from the pod in the volume then delete it and create a new pod with the same volume and show the created file by the first pod.

<details><summary>Solution</summary>
<p>

pv-data.yaml:
```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-data
spec:
  storageClassName: "local"
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: "/home/ubuntu/data"

```

pvc-data.yaml:
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-data
spec:
  storageClassName: "local"
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi

```

pvc-pod.yaml:
```yaml
apiVersion: v1
kind: Pod
metadata:
  labels:
    run: pvc-pod
  name: pvc-pod
spec:
  containers:
  - image: busybox:latest
    name: pvc-pod
    args:
      - sleep
      - "3600"
    volumeMounts:
    - name: data
      mountPath: "/data"
  volumes:
  - name: data
    persistentVolumeClaim:
      claimName: pvc-data

```

Create a pod with the PVC. Create a file on volume. Delete the pod and create a new one with the same volume. Check that the file has persisted.

```bash
kubectl apply -f pv-data.yaml
kubectl apply -f pvc-data.yaml
kubectl apply -f pvc-pod.yaml

kubectl get pv
NAME      CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM              STORAGECLASS   REASON   AGE
pv-data   1Gi        RWO            Retain           Bound    default/pvc-data   local                   20m

kubectl get pvc
NAME       STATUS   VOLUME    CAPACITY   ACCESS MODES   STORAGECLASS   AGE
pvc-data   Bound    pv-data   1Gi        RWO            local          20m

# Check that the volume has been mounted
kubectl exec pvc-pod -- ls /data/
file

# Create a new file
kubectl exec pvc-pod -- touch /data/file2

# Delete the pod
kubectl delete -f pvc-pod.yaml

# Copy the pvc-pod.yaml and change the name of the pod to pvc-pod-2
kubectl apply -f pvc-pod-2.yaml

# Check that the file from previous pod has persisted on volume
kubectl exec pvc-pod-2 -- ls /data/
file
file2
```
</p>
</details>
