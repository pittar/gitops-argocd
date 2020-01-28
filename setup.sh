#!/bin/bash

LANG=C

echo ""
echo "*****************************************************"
echo "**                                                 **"
echo "**  Demo Setup:                                    **"
echo "**    - Branch, rename files, commit, push.        **"
echo "**    - Install ArgoCD Operator.                   **"
echo "**    - Install Bitnami Sealed Secrets Operator.   **"
echo "**    - Copy Sealed Secrets public key.            **"
echo "**                                                 **"
echo "*****************************************************"

read -p 'Base apps url (e.g. apps.ocp.pitt.ca): ' APPS_BASE_URL
read -p 'Git repository url: ' GIT_URL
read -p 'Git branch (e.g. master): ' GIT_REF
echo ""
read -p 'Quay read/write username: ' quayrwuser
read -p 'Quay read/write email: ' quayrwemail
read -sp 'Quay read/write password: ' quayrwpass
echo ""
read -p 'Quay read-only username: ' quayrouser
read -p 'Quay read-only email: ' quayroemail
read -sp 'Quay read-only password: ' quayropass
echo ""

echo "Setting git branch."
if [[ "$GIT_REF" == "master" ]]; then
    echo "Using master branch."
else
    echo "Creating branch $GIT_REF."
    git checkout -b $GIT_REF
fi

if [[ "$OSTYPE" == "darwin"* ]]; then
    FIND_ROUTE_PREFIX=$'find $PWD \\( -type d -name .git -prune \\) -o -type f -print0 | xargs -0 sed -i \'\' \'s/apps\\.example\\.com/'
    FIND_REPO_PREFIX=$'find $PWD \\( -type d -name .git -prune \\) -o -type f -print0 | xargs -0 sed -i \'\' \'s/git\\.url\\.git/'
    FIND_BRANCH_PREFIX=$'find $PWD \\( -type d -name .git -prune \\) -o -type f -print0 | xargs -0 sed -i \'\' \'s/targetRevision:\ master/targetRevision:\ '
else
    FIND_ROUTE_PREFIX=$'find $PWD \\( -type d -name .git -prune \\) -o -type f -print0 | xargs -0 sed -i \'s/apps\\.example\\.com/'
    FIND_REPO_PREFIX=$'find $PWD \\( -type d -name .git -prune \\) -o -type f -print0 | xargs -0 sed -i \'s/git\\.url\\.git/'
    FIND_BRANCH_PREFIX=$'find $PWD \\( -type d -name .git -prune \\) -o -type f -print0 | xargs -0 sed -i \'s/targetRevision:\ master/targetRevision:\ '
fi

FIND_SUFFIX=$'/g\''

ROUTE=$(sed 's/\./\\./g' <<< $APPS_BASE_URL)
REPO=$(sed 's/\./\\./g' <<< $GIT_URL)
REPO=$(sed 's/\//\\\//g' <<< $REPO)
BRANCH=$(sed 's/\./\\./g' <<< $GIT_REF)

FIND_AND_REPLACE_ROUTE="$FIND_ROUTE_PREFIX$ROUTE$FIND_SUFFIX"
FIND_AND_REPLACE_REPO="$FIND_REPO_PREFIX$REPO$FIND_SUFFIX"
FIND_AND_REPLACE_BRANCH="$FIND_BRANCH_PREFIX$BRANCH$FIND_SUFFIX"

echo "Replacing Routes... "
echo "$FIND_AND_REPLACE_ROUTE"
echo "Replacing git repos..."
echo "$FIND_AND_REPLACE_REPO"
echo "Replacing git branches..."
echo "$FIND_AND_REPLACE_BRANCH"
echo ""

eval $FIND_AND_REPLACE_ROUTE
eval $FIND_AND_REPLACE_REPO
eval $FIND_AND_REPLACE_BRANCH
echo ""

echo "Adding/Committing/Pushing to the $GIT_REF branch of $GIT_URL"
git add --all
git commit -m "Updated routes and git repo urls/branches."
git push origin $GIT_REF
echo "Pushed!"

echo ""
echo "Installing Argo CD Operator."

echo "Create the Argo CD project."
oc adm new-project argocd

echo "Configure RBAC for Argo CD"
oc create -f install/argocd/deploy/service_account.yaml -n argocd
oc create -f install/argocd/deploy/role.yaml -n argocd
oc create -f install/argocd/deploy/role_binding.yaml -n argocd

echo "Add the Argo CRDs."
oc create -f install/argocd/deploy/argo-cd -n argocd

echo "Add the Argo CD Operator."
oc create -f install/argocd/deploy/crds/argoproj_v1alpha1_argocd_crd.yaml -n argocd
sleep 5

echo "There should be three CRDs."
oc get crd | grep argo

echo "Deploy the Operator."
oc create -f install/argocd/deploy/operator.yaml -n argocd

echo "Waiting for Argo CD operator to start."
sleep 15

while oc get deployment/argocd-operator -n argocd | grep "0/1" >> /dev/null;
do
    echo "Waiting..."
    sleep 3
done
echo "Argo CD Operator ready!"

echo "Create an instance of Argo CD."
oc create -f install/argocd/examples/argocd-minimal.yaml -n argocd

echo "Waiting for Argo CD to start."
sleep 15

while oc get deployment/argocd-server -n argocd | grep "0/1" >> /dev/null;
do
    echo "Waiting..."
    sleep 3
done
echo "Argo CD ready!"

echo ""
echo "Printing default admin password:"
oc -n argocd get pod -l "app.kubernetes.io/name=argocd-server" -o jsonpath='{.items[*].metadata.name}'
echo ""
echo ""

echo "Create config project for cluster configuration."
oc create -f gitops/projects/config-project.yaml
echo "Creating security app for security context constraints."
oc create -f gitops/applications/cluster-config/security-application.yaml
echo "Create sealed secrets application."
oc create -f gitops/applications/cluster-config/sealedsecrets-application.yaml

echo "Waiting for Bitnami Sealed Secrets controller to start."
sleep 15

while oc get deployment/sealed-secrets-controller -n openshift-secrets | grep "0/1" >> /dev/null;
do
    echo "Waiting..."
    sleep 3
done
echo "Sealed Secrets ready!"
echo ""

echo "Create dir for Sealed Secrets public key. (~/bitnami)."
mkdir -p ~/bitnami

echo "Get the public key from the Sealed Secrets secret."
oc get secret -o yaml -n openshift-secrets -l sealedsecrets.bitnami.com/sealed-secrets-key | grep tls.crt | cut -d' ' -f6 | base64 -D > ~/bitnami/publickey.pem

echo "Creting Sealed Secrets."
oc create secret docker-registry quay-cicd-secret --docker-server=quay.io --docker-username="$quayrwuser" --docker-password="$quayrwpass" --docker-email="$quayrwemail" -n cicd -o json --dry-run | kubeseal --cert ~/bitnami/publickey.pem > gitops/cicd/builds/quay-cicd-sealedsecret.json
oc create secret docker-registry quay-pull-secret --docker-server=quay.io --docker-username="$quayrouser" --docker-password="$quayropass" --docker-email="$quayroemail" -n petclinic-dev -o json --dry-run | kubeseal --cert ~/bitnami/publickey.pem > gitops/java/petclinic/overlays/dev/quay-pull-sealedsecret.json
oc create secret docker-registry quay-pull-secret --docker-server=quay.io --docker-username="$quayrouser" --docker-password="$quayropass" --docker-email="$quayroemail" -n petclinic-uat -o json --dry-run | kubeseal --cert ~/bitnami/publickey.pem > gitops/java/petclinic/overlays/uat/quay-pull-sealedsecret.json
# Need to write this one to disk temporarily in order to add a label to it.
mkdir -p ~/tmp/tmpsecrets
oc create secret generic quay-creds-secret --from-literal="username=$quayrwuser" --from-literal="password=$quayrwpass" -n cicd -o yaml --dry-run > ~/tmp/tmpsecrets/quay-creds.yaml
printf "  labels:\n    credential.sync.jenkins.openshift.io: \"true\"\n" >> ~/tmp/tmpsecrets/quay-creds.yaml
kubeseal --cert ~/bitnami/publickey.pem < ~/tmp/tmpsecrets/quay-creds.yaml > gitops/cicd/builds/quay-creds-sealedsecret.json
rm -rf ~/tmp/tmpsecrets

echo "Adding/Committing/Pushing sealed secrets to the $GIT_REF branch of $GIT_URL"
git add --all
git commit -m "Updated routes and git repo urls/branches."
git push origin $GIT_REF
echo "Pushed!"

echo "Done!"
