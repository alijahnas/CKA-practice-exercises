# Security (12%)

## Know how to configure authentication and authorization

Docs:
- https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/
- https://kubernetes.io/docs/reference/access-authn-authz/rbac/

Questions:
- Create a service account name lister, give it the ability to list pods.
- Launch a busybox pod with this service account and list pods from within the pod (podception) using curl. Check that other resources like services are forbidden.

<details><summary>Solution</summary>
<p>

pod-sa.yml:
```yaml
apiVersion: v1
kind: Pod
metadata:
  labels:
    run: podsa
  name: podsa
spec:
  serviceAccountName: lister
  containers:
  - image: tutum/curl:latest
    name: podsa
    command: ["sleep","3600"]
```

```bash
# Creating the lister service account and giving it the capabilities
kubectl create serviceaccount lister
kubectl create role lister-role --verb=get,watch,list --resource=pods
kubectl create rolebinding lister-rolebinding --role=lister-role --serviceaccount=default:lister

kubectl apply -f pod-sa.yml
kubectl exec -it podsa -- bash
# From within the pod now
API=https://$KUBERNETES_SERVICE_HOST:$KUBERNETES_SERVICE_PORT
TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
CACERT=/var/run/secrets/kubernetes.io/serviceaccount/ca.crt
NAMESPACE=$(cat /var/run/secrets/kubernetes.io/serviceaccount/namespace)
# Listing pods
curl -H "Authorization: Bearer $TOKEN" --cacert $CACERT $API/api/v1/namespaces/$NAMESPACE/pods
  "kind": "PodList",
  "apiVersion": "v1",
  "metadata": {
    "selfLink": "/api/v1/namespaces/default/pods",
    "resourceVersion": "1085753"
  },
  "items": [
    {
...

# Trying to list services is forbidden
curl -H "Authorization: Bearer $TOKEN" --cacert $CACERT $K8S/api/v1/amespaces/$NAMESPACE/service
{
  "kind": "Status",
  "apiVersion": "v1",
  "metadata": {
    
  },
  "status": "Failure",
  "message": "service is forbidden: User \"system:serviceaccount:default:lister\" cannot list resource \"service\" in API group \"\" in the namespace \"default\"",
  "reason": "Forbidden",
  "details": {
    "kind": "service"
  },
  "code": 403
}
```

</p>
</details>


## Understand Kubernetes security primitives

Docs:
- https://kubernetes.io/docs/tasks/administer-cluster/securing-a-cluster/
- https://kubernetes.io/docs/concepts/configuration/secret/
- https://kubernetes.io/docs/concepts/policy/pod-security-policy/

## Know how to configure network policies

Doc: https://kubernetes.io/docs/concepts/services-networking/network-policies/

Be sure to have deployed a CNI that supports network policies like Calico.

Questions:
- Create one busybox pod with label `role: client` and one deployment of two nginx pods with label `role: server`. Expose the nginx port 80 with a service.
- Create a network policy that denies all ingress traffic. Check that the busybox pod can't reach the nginx service.
- Add one exception for port 80 from the busybox pod and check again connectivity to the nginx service.

<details><summary>Solution</summary>
<p>

server-client.yml:
```yaml
---
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: nginx
    role: server
  name: nginx-deploy
spec:
  replicas: 2
  selector:
    matchLabels:
      app: nginx
      role: server
  template:
    metadata:
      labels:
        app: nginx
        role: server
    spec:
      containers:
      - image: nginx:latest
        name: nginx

---
apiVersion: v1
kind: Service
metadata:
  name: nginx
spec:
  selector:
    app: nginx
    role: server
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80

---
apiVersion: v1
kind: Pod
metadata:
  labels:
    role: client
  name: busybox
spec:
  containers:
  - image: busybox:latest
    name: busybox
    args:
      - sleep
      - "3600"

---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny
spec:
  podSelector: {}                                                                    
  policyTypes:
  - Ingress

```

```bash
kubectl apply -f server-client.yml
kubectl exec busybox -- wget nginx
```

allow-80.yml
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-80
spec:
  podSelector:
    matchLabels:
      role: server
  ingress:
  - from:
    - podSelector:
        matchLabels:
          role: client
    ports:
    - port: 80

```

```bash
kubectl apply -f allow-80.yml
kubectl exec busybox -- wget nginx
```

</p>
</details>


## Create and manage TLS certificates for cluster components

Docs:
- https://kubernetes.io/docs/concepts/cluster-administration/certificates/
- https://kubernetes.io/docs/tasks/tls/managing-tls-in-a-cluster/

Kelsey Hightower, in his now famous Kubernetes the hard way, has a great guide on creating and distributing certificates for cluster components here: [Certificates the hard way](https://github.com/kelseyhightower/kubernetes-the-hard-way/blob/master/docs/04-certificate-authority.md)

Kubernetes also offers an [API](https://kubernetes.io/docs/tasks/tls/managing-tls-in-a-cluster/) to provision TLS certificates signed by a CA that you control.

Questions:
- Create a certificate signing request with `cfssl` for a user named `new-admin` and create a certificate through the API that it will use to authenticate, and give it the cluster-admin role.
- Create a config with this user and list nodes with it.

<details><summary>Solution</summary>
<p>

```bash
# Download cfssl first
wget -q --show-progress --https-only --timestamping https://pkg.cfssl.org/R1.2/cfssl_linux-amd64 https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64
chmod +x cfssl_linux-amd64 cfssljson_linux-amd64
sudo mv cfssl_linux-amd64 /usr/local/bin/cfssl
sudo mv cfssljson_linux-amd64 /usr/local/bin/cfssljson

cat << EOF | cfssl genkey - | cfssljson -bare new-admin
{
  "CN": "new-admin",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "FR",
      "L": "Paris",
      "O": "system:authenticated",
      "OU": "CKA practice exercises",
      "ST": "IDF"
    }
  ]
}
EOF

cat << EOF > new-admin-csr.yml
apiVersion: certificates.k8s.io/v1beta1
kind: CertificateSigningRequest
metadata:
  name: new-admin-csr
spec:
  request: $(cat new-admin.csr | base64 | tr -d '\n')
  usages:
  - digital signature
  - key encipherment
  - client auth
EOF

kubectl apply -f new-admin-csr.yml

# Approve the CSR through the API
kubectl certificate approve new-admin-csr

# Get the signed certificate
kubectl get csr new-admin-csr -o jsonpath='{.status.certificate}' | base64 --decode > new-admin.crt

# Create a ClusterRoleBinding for user new-admin and give cluster-admin role
kubectl create clusterrolebinding cluster-new-admin --clusterrole=cluster-admin --user=new-admin

# Create config for user new-admin
kubectl config set-credentials new-admin --client-certificate=new-admin.crt --client-key=new-admin-key.pem --embed-certs=true
kubectl config set-context new-admin@kubernetes --cluster=kubernetes --user=new-admin
kubectl config view
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: DATA+OMITTED
    server: https://172.16.1.11:6443
  name: kubernetes
contexts:
- context:
    cluster: kubernetes
    user: kubernetes-admin
  name: kubernetes-admin@kubernetes
- context:
    cluster: kubernetes
    user: new-admin
  name: new-admin@kubernetes
current-context: new-admin@kubernetes
kind: Config
preferences: {}
users:
- name: kubernetes-admin
  user:
    client-certificate-data: REDACTED
    client-key-data: REDACTED
- name: new-admin
  user:
    client-certificate-data: REDACTED
    client-key-data: REDACTED

# Use context to list nodes
kubectl config use-context new-admin@kubernetes
Switched to context "new-admin@kubernetes".

kubectl get nodes
NAME           STATUS   ROLES    AGE   VERSION
k8s-master     Ready    master   5d    v1.18.0
k8s-worker-1   Ready    <none>   5d    v1.18.0
k8s-worker-2   Ready    <none>   5d    v1.18.0

```

</p>
</details>

## Work with images securely

Docs:
- https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/
- https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/#add-imagepullsecrets-to-a-service-account

## Define security contexts

Doc: https://kubernetes.io/docs/tasks/configure-pod-container/security-context/

Questions:
- Create a pod that runs as user with ID 9001, group 9002, and check the ids from within the pod

<details><summary>Solution</summary>
<p>

pod-context.yml:
```yaml
apiVersion: v1
kind: Pod
metadata:
  labels:
    run: over9000
  name: over9000
spec:
  securityContext:
    runAsUser: 9001
    runAsGroup: 9002
  containers:
  - image: busybox:latest
    name: over9000
    args:
      - sleep
      - "9001"

```

```bash
kubectl apply -f pod-context.yml
kubectl exec over9000 -- id
uid=9001 gid=9002
```

</p>
</details>

## Secure persistent key value store

For securing etcd check: https://kubernetes.io/docs/tasks/administer-cluster/configure-upgrade-etcd/#securing-etcd-clusters

For encrypting data at rest check: https://kubernetes.io/docs/tasks/administer-cluster/encrypt-data/

For secrets usage check [Application configuration with secrets](https://kubernetes.io/docs/tasks/tls/managing-tls-in-a-cluster/)
