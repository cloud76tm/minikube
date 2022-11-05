#!/bin/bash

minikube start \
--container-runtime=docker \
--cni=$PWD/cni/calico.yaml \
--kubernetes-version=v1.25.2 \
--nodes=2

minikube addons disable default-storageclass
minikube addons disable storage-provisioner

kubectl apply -f manifests/storage-provisioner.yaml 
