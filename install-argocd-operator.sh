#!/bin/bash

echo "Create argocd project."
oc new-project argocd

echo "Create Argo CD service account, role, and role binding."
oc create -f https://raw.githubusercontent.com/argoproj-labs/argocd-operator/master/deploy/service_account.yaml
oc create -f https://raw.githubusercontent.com/pittar/argocd-demo/master/deploy/role.yaml
oc create -f https://raw.githubusercontent.com/argoproj-labs/argocd-operator/master/deploy/role_binding.yaml
# Until I figure out how configure the argocd role to be able to create namespacdes...
# oc adm policy add-cluster-role-to-user cluster-admin system:serviceaccount:argocd:argocd-application-controller
sleep 3

echo "Add the Argo CD CRDs."
oc create -f https://raw.githubusercontent.com/argoproj-labs/argocd-operator/master/deploy/argo-cd/argoproj_v1alpha1_appproject_crd.yaml
oc create -f https://raw.githubusercontent.com/argoproj-labs/argocd-operator/master/deploy/argo-cd/argoproj_v1alpha1_application_crd.yaml
sleep 3

echo "Add the Argo CD operator CRD."
oc create -f https://raw.githubusercontent.com/argoproj-labs/argocd-operator/master/deploy/crds/argoproj_v1alpha1_argocd_crd.yaml
sleep 3

echo "Listing CRDs.  There should be three!"
oc get crd | grep argo
sleep 3
echo "Deploy the operator."
oc create -f https://raw.githubusercontent.com/argoproj-labs/argocd-operator/master/deploy/operator.yaml
sleep 3

echo "Create an Argo CD instance."
oc create -f https://raw.githubusercontent.com/pittar/argocd-demo/master/deploy/argocd.yaml
echo "Waiting 10 seconds for the pods to be created..."
sleep 10
echo "Printing default admin password:"
oc -n argocd get pod -l "app.kubernetes.io/name=argocd-server" -o jsonpath='{.items[*].metadata.name}'

echo "Enjoy!"
