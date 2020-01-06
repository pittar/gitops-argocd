#!/bin/bash

echo "Quay pull secret for projects."
echo "Enter your Quay.io username and password when prompted:"

read -p 'Project prefix (e.g. petclinic): ' projectprefix
read -p 'Username: ' quayuser
read -p 'Email: ' quayemail
read -sp 'Password: ' quaypass
echo ""

devproject="$projectprefix-dev"
uatproject="$projectprefix-uat"

echo "Creating quay pull secret in $devproject and $uatproject projects"
oc create secret docker-registry quay-cicd-secret --docker-server=quay.io --docker-username="$quayuser" --docker-password="$quaypass" --docker-email="$quayemail" -n "$devproject"
oc create secret docker-registry quay-cicd-secret --docker-server=quay.io --docker-username="$quayuserr" --docker-password="$quaypass" --docker-email="$quayemail" -n "$uatproject"

oc secrets link default quay-cicd-secret --for=pull -n "$devproject"
oc secrets link default quay-cicd-secret --for=pull -n "$uatproject"