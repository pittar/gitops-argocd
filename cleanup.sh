#!/bin/bash

# Deleting sealed secrets pem dir.
rm -rf ~/bitnami

# Delete CRDs and ClusterRoles
oc delete crd/applications.argoproj.io
oc delete crd/appprojects.argoproj.io 
oc delete crd/argocds.argoproj.io 
oc delete crd/sealedsecrets.bitnami.com
oc delete clusterrole/argocd-application-controller
oc delete clusterrole/argocd-server
oc delete clusterrolebinding/argocd-application-controller
oc delete clusterrolebinding/argocd-server
oc delete clusterrole/secrets-unsealer
oc delete clusterrolebinding/sealed-secrets-controller

# Delete sealed secrets project.
oc delete project openshift-secrets
# Delete argocd project.
oc delete project argocd