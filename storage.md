# Storage (7%)

## Understand persistent volumes and know how to create them

Doc: https://kubernetes.io/docs/concepts/storage/persistent-volumes/

Questions:
- Create a pod and mount a volume with hostPath directory.
- Check that the contents of the directory are accessible through the pod.

<details><summary>Solution</summary>
<p>

pv-pod.yml:
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
# Create directory and file inside it
mkdir /home/ubuntu/data
touch data/file

kubectl apply -f pv-pod.yml
kubectl exec pv-pod -- ls /data
file
```

</p>
</details>

## Understand access modes for volumes

Doc: https://kubernetes.io/docs/concepts/storage/persistent-volumes/#access-modes

## Understand persistent volume claims primitive

Doc: https://kubernetes.io/docs/concepts/storage/persistent-volumes/#access-modes

Questions:
- Create a persistent volume from hostPath and a persistent volume claim corresponding tothat PV. Create a pod that uses the PVC and check that the volume is mounted in the pod.
- Create a file from the pod in the volume then delete it and create a new pod with the same volume and show the created file by the first pod.

<details><summary>Solution</summary>
<p>

pv-data.yml:
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

pvc-data.yml:
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

pvc-pod.yml:
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
kubectl apply -f pv-data.yml
kubectl apply -f pvc-data.yml
kubectl apply -f pvc-pod.yml

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
kubectl delete -f pvc-pod.yml

# Copy the pvc-pod.yml and change the name of the pod to pvc-pod-2
kubectl apply -f pvc-pod-2.yml

# Check that the file from previous pod has persisted on volume
kubectl exec pvc-pod-2 -- ls /data/
file
file2
```

</p>
</details>


## Understand Kubernetes storage objects

Docs:
- Persistent Volumes: https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistent-volumes
- Persistent Volume Claims: https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistentvolumeclaims
- Storage classes: https://kubernetes.io/docs/concepts/storage/storage-classes/

## Know how to configure applications with persistent storage

Doc: https://kubernetes.io/docs/tasks/configure-pod-container/configure-volume-storage/

<details><summary>Solution</summary>
<p>

Check the section [Understand persistent volume claims primitive](https://github.com/alijahnas/CKA-practice-exercises/blob/master/storage.md#understand-persistent-volume-claims-primitive) above.

</p>
</details>
