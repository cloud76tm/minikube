# **Day Two: Kubernetes Resource**

## *<u>Deploy an App with Deployment</u>*

**1. Create a Deployment using kubectl**  
Open a Ubuntu Terminal. Type the following:
```
kubectl create deployment kubernetes-bootcamp \
--image=gcr.io/google-samples/kubernetes-bootcamp:v1
```
*Output*
```   
deployment.apps/kubernetes-bootcamp created
```
**2. Get the list Deployments in your Kubernetes cluster**
```
kubectl get deployments
```
*Output*
```   
NAME                  READY   UP-TO-DATE   AVAILABLE   AGE
kubernetes-bootcamp   1/1     1            1           84s
```
**3. Run the proxy in a second terminal**
```
kubectl proxy
```
*Output*
```   
Starting to serve on 127.0.0.1:8001
```
**4. Access your App through the proxy**
```
curl http://localhost:8001/version
```
*Output*
```   
{
  "major": "1",
  "minor": "25",
  "gitVersion": "v1.25.2",
  "gitCommit": "5835544ca568b757a8ecae5c153f317e5736700e",
  …
}
```
**5. Get the pod name**
```
kubectl get pod -o jsonpath={.items[*].metadata.name}
```
*Output*
```   
kubernetes-bootcamp-75c5d958ff-9frwd
```
**6. Execute command directly on the pod’s container**
```
kubectl exec <POD_NAME> -- env
```
*Output*
```   
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
HOSTNAME=kubernetes-bootcamp-75c5d958ff-9frwd
KUBERNETES_PORT_443_TCP_ADDR=10.96.0.1
…
```
**7. Working with a bash session in the pod’s container**
```
$ kubectl exec -it <POD_NAME> -- bash   
root@<POD_NAME>:/#
root@<POD_NAME>:/# cat server.js
var http = require('http');
var requests=0;
var podname= process.env.HOSTNAME; 
var startTime;
…
root@<POD_NAME>:/# curl http://localhost:8080
Hello Kubernetes bootcamp! | Running on: <POD_NAME> | v=1
```

## *<u>Expose your App</u>*

**1. Create a new service using kubectl**
```
kubectl expose deployment/kubernetes-bootcamp --type=NodePort --port 8080
```
*Output*
```   
service/kubernetes-bootcamp exposed
```
**2. Get the list services**
```
kubectl get services
```
*Output*
```   
NAME				     TYPE          CLUSTER-IP     EXTERNAL-IP   PORT(S)…
kubernetes-bootcamp   NodePort    10.100.144.5      <none>              8080:31196/TC...
```
**7. Check the node and node IP where the pod is located**
```
kubectl get pod -l app=kubernetes-bootcamp –o jsonpath={.items..status.hostIP}
```
*Output*
```   
192.168.49.3
```
**3. Access your App through the service**
```
*Output*
```   
curl http://192.168.49.3:31196
```
*Output*
```   
Hello Kubernetes bootcamp! | Running on: <POD_NAME> | v=1
```
**7. Get the service details**
```
kubectl describe service kubernetes-bootcamp
```
*Output*
```   
Name:                     kubernetes-bootcamp
Namespace:           default
Labels:                   app=kubernetes-bootcamp
…
```
**4. Get the endpoint details**
```
kubectl get endpoints
```
*Output*
```   
NAME			ENDPOINTS		AGE
kubernetes			192.168.49.2:8443	6h55m
kubernetes-bootcamp   	10.244.205.194:8080	34m
```
kubectl describe endpoints kubernetes-bootcamp
```
*Output*
```   
Name:         	kubernetes-bootcamp
Namespace:    default
Labels:       	app=kubernetes-bootcamp
…
```
**5. Change selector of the service**
```
$ kubectl edit service kubernetes-bootcamp
…
  selector:
    app=kubernetes-bootcamp >>>>> version: v1
…
```
*Output*
```   
service/kubernetes-bootcamp edited
```
**6. Get the service details**
```
kubectl describe service kubernetes-bootcamp
```
*Output*
```   
…
Endpoints:                <none>
…
```
## *<u>Separate code from image using a ConfigMap</u>*

**1. Copy app code from pod**
```
kubectl cp <POD_NAME>:server.js server.js
```
**2. Edit server.js**
```
  response.writeHead(200);
  response.write("Hello Kubernetes bootcamp! | Running on: ");
  # change to the following line
  response.write("Hello Kubernetes bootcamp!\nRunning on: ");
  response.write(host);
```
**3. Create a ConfigMap**
```
kubectl create configmap server-js --from-file=server.js
```
*Output*
```  
configmap/server-js created
```
**4. Check the ConfigMap**
```
kubectl get configmap server-js -o yaml
```
*Output*
```  
apiVersion: v1
kind: ConfigMap
data:
  server.js: |
    …
      response.write("Hello Kubernetes!\n");
      response.write("Running on: ");
      response.write(host);
    …
```
**5. Edit the deployment**
```
kubectl edit deployment kubernetes-bootcamp
...
        terminationMessagePolicy: File
        volumeMounts:
        - name: server
          mountPath: "/server.js”
          subPath: “server.js”
          readOnly: true
      volumes:
         - name: server
           configMap:
              name: server-js
      dnsPolicy: ClusterFirst
```
**6. Get pod status**
```
kubectl get pods
```
*Output*
```  
NAME                                    READY      STATUS         RESTARTS ..
kubernetes-bootcamp-55479b8d86-sd7tp    1/1        Terminating    0…
kubernetes-bootcamp-645db76c97-q8ff8    1/1        Running        0…
```
**7. Access your App through the service**
```
curl http://127.0.0.1:59821
```
*Output*
```  
Hello Kubernetes!
Running on: kubernetes-bootcamp-645db76c97-q8ff8 | v=1
```