# **Day Three: Deploying Workloads**

## *Install & Setup NFS Provisioner Operator*

**1. Install Operator Lifecycle Manager (OLM)**
```
curl -sL https://github.com/operator-framework/operator-lifecycle-manager/releases/download/v0.22.0/install.sh | \
bash -s v0.22.0
```
**2. Verify installation**
```
kubectl -n olm get all
```
**3. Install NFS Provisioner Operator**
```
kubectl create -f https://operatorhub.io/install/nfs-provisioner-operator.yaml
```
**4. Verify installation**
```
kubectl -n operators get csv
```
**5. Prepare NFS Provisioner deployment***
```
kubectl label node minikube-m02 app=nfs-provisioner
kubectl get node -l app=nfs-provisioner
```
**6. Deploy NFS Provisioner**
``` 
kubectl -n kube-system create -f - <<EOF
apiVersion: cache.jhouse.com/v1alpha1
kind: NFSProvisioner
metadata:
  name: nfsprovisioner
spec:
  nfsImageConfiguration:
    image: k8s.gcr.io/sig-storage/nfs-provisioner@sha256:e943bb77c7df05ebdc8c7888b2db289b13bf9f012d6a3a5a74f14d4d5743d439
    imagePullPolicy: IfNotPresent
  nodeSelector:
    app: nfs-provisioner
  hostPathDir: "/data"
EOF
```
**7. Verify NFS Provisioner**
```
kubectl -n kube-system get pod
kubectl -n kube-system get pvc
kubectl get sc
```

## *Deploying a MariaDB using Helm*

**1. Install Helm**
```
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```
**2.Verify installation**
```
helm version
```
**3.Add the Bitnami repository**
```
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
```
**4.Check properties and defaults**
```
helm show values bitnami/mariadb
```
**5.Deploy a MariaDB**
```
helm install mariadb --namespace bookstack --create-namespace \
--set architecture=replication \
--set auth.rootPassword=p@ssw0rd \
--set auth.replicationPassword=p@ssw0rd  \
--set primary.persistence.storageClass=standard \
--set primary.persistence.size=4Gi \
--set primary.nodeSelector="kubernetes.io/hostname: minikube-m02" \
--set secondary.persistence.storageClass=standard \
--set secondary.persistence.size=4Gi \
--set secondary.nodeSelector="kubernetes.io/hostname: minikube-m02" \
bitnami/mariadb
```
**6. Verify installation**
```
kubectl -n bookstack get all
NAME                     READY      STATUS     RESTARTS     AGE
pod/mariadb-primary-0    1/1        Running    0            10s
pod/mariadb-secondary-0  1/1        Running    0            10s
```
**7. Create DB user and database**
```
kubectl -n bookstack exec -it mariadb-primary-0 -- mysql -u root -p 
Enter password: 
…
MariaDB [(none)]> create database bookstackapp;
Query OK, 1 row affected (0.042 sec) 
MariaDB [(none)]> create user bookstack identified by 'p@ssw0rd';
Query OK, 0 rows affected (0.054 sec) 
MariaDB [(none)]> grant all privileges on bookstackapp.* to 'bookstack'@'%';
Query OK, 0 rows affected (0.051 sec) 
MariaDB [(none)]> flush privileges; 
Query OK, 0 rows affected (0.036 sec) 
MariaDB [(none)]> 
```

## *Create a ConfigMap, Secret and PVC*

**1. Create a ConfigMap for Bookstack Config**
```
kubectl -n bookstack create configmap bookstack-config \
--from-literal=PUID=1000 \
--from-literal=PGID=1000 \
--from-literal=DB_HOST=mariadb-primary \
--from-literal=APP_URL=”http://localhost:8080"
```
**2. Create a Secret for DB Config**
```
kubectl -n bookstack create secret generic bookstack-db-config \
--from-literal=DB_USER=bookstack \
--from-literal=DB_PASS=p@ssw0rd \
--from-literal=DB_DATABASE=bookstackapp
```
**3. reate a PVC for Bookstack Data**
```
kubectl -n bookstack create -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: bookstack-data
spec:
  storageClassName: nfs
  accessModes:
  - ReadWriteMany
  resources:
    requests:
      storage: 1Gi
  volumeMode: Filesystem
EOF
```

## *Create a Deployment*

**1. Create a Deployment**
```
kubectl -n bookstack create -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: bookstack
  name: bookstack
spec:
  selector:
    matchLabels:
      app: bookstack
  template:
    metadata:
      labels:
        app: bookstack
    spec:
      containers:
      - image: lscr.io/linuxserver/bookstack:latest
        imagePullPolicy: Always
        name: bookstack
        envFrom: 
        - configMapRef:
            name: bookstack-config
        - secretRef:
            name: bookstack-db-config
        ports:
        - containerPort: 80
          protocol: TCP
        volumeMounts:
        - mountPath: /config
          name: bookstack-data
      volumes:
      - name: bookstack-data
        persistentVolumeClaim:
          claimName: bookstack-data
EOF
```
**2. Verify installation**
```
kubectl -n bookstack get pod
```
*Outout*
```
NAME                            READY   STATUS    RESTARTS   AGE
pod/bookstack-78fc54c967-vxc9r	1/1		Running   0          9s
pod/mariadb-primary-0           1/1		Running   0          37m
pod/mariadb-secondary-0         1/1		Running   0          37m
```
```
kubectl -n bookstack logs -l app=bookstack
```
*Outout*
```
s6-rc: info: service init-services successfully started
s6-rc: info: service legacy-services: starting
services-up: info: copying legacy longrun cron (no readiness notification)
services-up: info: copying legacy longrun memcached (no readiness notification)
services-up: info: copying legacy longrun nginx (no readiness notification)
services-up: info: copying legacy longrun php-fpm (no readiness notification)
s6-rc: info: service legacy-services successfully started
s6-rc: info: service 99-ci-service-check: starting
[ls.io-init] done.
s6-rc: info: service 99-ci-service-check successfully started
```

## *Expose the Deployment*

**1. Expose the Deployment**
```
kubectl -n bookstack expose deployment/bookstack \
--type=LoadBalancer \
--port 8080 \
--target-port=80
```
**2. Start minikube tunnel**
Open the other terminal
```
minikube tunnel
```
**3. Verify service**
```
kubectl -n bookstack get service
```
*Outout*
```
NAME				TYPE			CLUSTER-IP		EXTERNAL-IP	PORT(S) …
bookstack			LoadBalancer	10.111.110.10 	127.0.0.1		8080:32507/TCP…
mariadb-primary		ClusterIP		10.110.209.230	<none>			3306/TCP…
mariadb-secondary	ClusterIP		10.111.66.255	<none>			3306/TCP…
```
**4. Access Bookstack**  
The default username is **admin@admin.com** with the password of **password**, , access the workload at http://localhost:8080
