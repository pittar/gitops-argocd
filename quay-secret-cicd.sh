#!/bin/bash

echo "Enter your Quay.io username and password when prompted:"

read -p 'Username: ' quayuser
read -p 'Email: ' quayemail
read -sp 'Password: ' quaypass
echo ""

echo "Creating quay pull secret in cicd project"
oc create secret docker-registry quay-cicd-secret --docker-server=quay.io --docker-username="$quayuser" --docker-password="$quaypass" --docker-email="$quayemail" -n cicd
#oc create secret docker-registry quay-cicd-secret --docker-server=quay.io --docker-username="pittar" --docker-password='Initech0627!' --docker-email=apitt@redhat.com -n petclinic-dev
#oc create secret docker-registry quay-cicd-secret --docker-server=quay.io --docker-username="pittar" --docker-password='Initech0627!' --docker-email=apitt@redhat.com -n petclinic-uat
oc secrets link default quay-cicd-secret --for=pull -n cicd
#oc secrets link default quay-cicd-secret --for=pull -n petclinic-dev
#oc secrets link default quay-cicd-secret --for=pull -n petclinic-dev

echo "Creating quay creds for skopeo Jenkins node to use."
oc create secret generic quay-creds-secret --from-literal="username=$quayuser" --from-literal="password=$quaypass" -n cicd
oc label secret quay-creds-secret credential.sync.jenkins.openshift.io=true -n cicd
