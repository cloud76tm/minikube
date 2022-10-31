# **Day Five: Administer a Kubernetes Cluster**

## *Manage Pod Resources*

**1. Change bookstack namespace to the default namespace**
```
kubectl config set-context --current --namespace=bookstack
```
**2. Create a Limit Ranage and a Quota**
```
kubectl apply -f manifests/resource-quota.yaml
kubectl apply -f manifests/limit-range.yaml
```
**3. Verify Limits**
```
kubectl describe limitrange bookstack
```
*Outputs*
```
Name:       bookstack
Namespace:  bookstack
Type			Resource	Min		Max		Default Request	Default Limit  …
----			--------		---		---		---------------		-------------
Container	memory		256Mi	1Gi		256Mi			512Mi          -
Container	cpu			250m	1		250m			500m           -
```
```
kubectl describe resourcequota bookstack
```
*Outputs*
```
Name:		bookstack
Namespace:	bookstack
Resource	Used	Hard
--------		----	----
limits.cpu	1	1
limits.memory	1Gi	1Gi
```
**4. Check resource config of the bookstack Pod**
```
kubectl get pod -l app=bookstack \
-o jsonpath='{.items[0].spec.containers[0].resources}’
```
**5. Redeploy bookstack Pod**
```
kubectl rollout restart deployment bookstack
```
**6. Verify resource config**
```
kubectl get pod -l app=bookstack \
-o jsonpath='{.items[0].spec.containers[0].resources}’
```
*Outputs*
```
{"limits":{"cpu":"500m","memory":"512Mi"},"requests":{"cpu":"250m","memory":"256Mi"}}
```
**7. Change replicas from 1 to 3**
```
kubectl scael deployment bookstack --replicas=3
```
**8. Verify Pod and ReplicaSet**
```
kubectl get pod,replicaset -l app=bookstack
```
*Outputs*
```
NAME				READY	STATUS		RESTARTS	AGE
pod/bookstack-698f45bbc5-bvkll		1/1	Running		0		13m
pod/bookstack-698f45bbc5-p6v5k		1/1	Running		0		26m

NAME				DESIRED	CURRENT	READY	AGE
replicaset.apps/bookstack-698f45bbc5	3		2		2	33m
```
**9. Check ReplicaSet events**
```
kubectl describe replicaset.apps/bookstack-698f45bbc5
```
*Outputs*
```
Warning  FailedCreate      4s (x30 over 21m)  replicaset-controller Error creating: pods "bookstack-698f45bbc5-lvd2w" is forbidden: exceeded quota: bookstack…
```

## *Declare Network Policy*

**1. Create a Namespace and change it to the default namespace**
```
kubectl create namespace nginx
kubectl config set-context --current --namespace=nginx
```
**2. Create a Deployment for NGINX**
```
kubectl create deployment nginx --image=nginx
```
**3. Expose the Deployment**
```
kubectl expose deployment nginx --port=80
```
**4. Verify Pod and Service**
```
kubectl get svc,pod
```
**5. Test the service by accessing it from another Pod**
```
kubectl run busybox --rm -ti --image=busybox:1.28 -- /bin/sh
If you don't see a command prompt, try pressing enter.
/ #  wget --spider --timeout=1 nginx
Connecting to nginx (10.96.18.154:80)
/ #
```
**6. Create a Network Policy to limit access**
```
cat manifests/access-nginx.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: access-nginx
spec:
  podSelector:
    matchLabels:
      app: nginx
  ingress:
  - from:
    - podSelector:
        matchLabels:
          access: "true"

kubectl apply -f manifests/access-nginx.yaml
```
**7, Test access to the service without label**
```
kubectl run busybox --rm -ti --image=busybox:1.28 -- /bin/sh
If you don't see a command prompt, try pressing enter.
/ #  wget --spider --timeout=1 nginx
Connecting to nginx (10.96.18.154:80)
wget: download timed out
```
**8. Test access to the service with label**
```
kubectl run busybox --rm -ti --labels="access=true" \
--image=busybox:1.28 -- /bin/sh
If you don't see a command prompt, try pressing enter.
/ #  wget --spider --timeout=1 nginx
Connecting to nginx (10.96.18.154:80)
/ #
```