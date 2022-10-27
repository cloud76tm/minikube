# **Day One: Kubernetes 101**

## *<u>Create a Kubernetes cluster using minikube</u>*

### **1. Check Windows version**  
  * Select Windows logo key + R, type winver
  * You must be running Windows 10 version 2004 (Build 19041 and higher) or Windows 11
### **2. Check Windows version**
  * Enable WSL (Windows Subsystem for Linux)  
  Open a command prompt. Type the following:
    ```
    dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
    ```
  * Enable the Virtual Machine Platform  
  Type the following:
    ```
    dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
    ```
  * Update Linux kernel  
  Install the latest [WSL2 Linux kernel update package for x64 machines](https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi)
  * Reboot
  * Set WSL 2 as the default version  
  Open a command prompt. Type the following:
    ```
    wsl --set-default-version 2
    ```
### **3. Install Linux distribution**
  * Open the Microsoft Store and select **Ubuntu 20.04.5 LTS**
  * After completing the installation, Open **Ubuntu** using the Start menu
  * You will be asked to create a **Username** and **Password**
### **4. Install Docker on the WSL2**
Open a Ubuntu Terminal. Type the following:
  * Update package index and Install packages to use a repository over HTTPS
    ```
    sudo apt-get update && sudo apt-get install ca-certificates curl gnupg lsb-release 
    ```
  * Add Docker’s official GPG key   
    ```
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg 
    ```
  * Set up the repositofy
    ```
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null 
    ```
  * Install docker engine
    ```
    sudo apt-get update sudo apt-get install -y docker-ce docker-ce-cli containerd.io
    ```
### **5. Install minikube and kubelet**
Open a Ubuntu Terminal. Type the following:
  * Install minikube
    ```
    curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
    sudo install minikube-linux-amd64 /usr/local/bin/minikube
    ```
  * Install kubectl
    * Download Google Cloud public signing key 
      ```
      sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg \
      https://packages.cloud.google.com/apt/doc/apt-key.gpg 
      ```
    * Set up the repository
      ```
      echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list 
      ```
    * Update package index and Install kubectl
      ```
      sudo apt-get update && sudo apt-get install -y kubectl
      ```
### **6. Create a Kubernetes cluster**
Open a Ubuntu Terminal. Type the following:
  * Clone git repository
    ```
    git clone https://github.com/cloud76tm/minikube.git
    cd minikube
    ```
  * Create a cluster
    ```
    minikube start \
    --container-runtime=docker \
    --cni=$PWD/cni/calico.yaml \
    --kubernetes-version=v1.25.2 \
    --nodes=2 
    ```
  * Verify Installation
    ```
    kubectl get pod -A
    ```
### **7. Post Installation**
Open a Ubuntu Terminal. Type the following:
  * Disable minikube addons
    ```
    minikube addons list
    minikube addons disable storage-provisioner
    minikube addons disable default-storageclass
    ```
  * Deploy storage-provisioner and Create a StorageClass
    ```
    kubectl apply -f ./manifest/storage-provisioner.yaml
    ```
  * Verify Installation
    ```
    kubectl -n kube-system get pod
    kubectl get storageclass
    ```