#!/bin/bash

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
quayrwpass="\'$quayrwpass\'"
echo ""
read -p 'Quay read-only username: ' quayrouser
read -p 'Quay read-only email: ' quayroemail
read -sp 'Quay read-only password: ' quayropass
quayropass="\'$quayropass\'"
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

FIND_AND_REPLACE_ROUTE=$FIND_ROUTE_PREFIX$ROUTE$FIND_SUFFIX
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

echo "Installing Bitnami Sealed Secrets controller."
oc adm new-project openshift-secrets 
oc create -f install/bitnami/sealedsecrets.yaml
oc adm policy add-scc-to-user anyuid -z sealed-secrets-controller -n openshift-secrets

echo "Waiting for Bitnami Sealed Secrets controller to start."
sleep 2

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
oc create secret docker-registry quay-cicd-secret --docker-server=quay.io --docker-username="$quayrwuser" --docker-password="$quayrwpass" --docker-email="$quayrwemail" -n cicd -o json | kubeseal --cert ~/bitnami/publickey.pem > gitops/cicd/builds/quay-cicd-sealedsecret.json
oc create secret docker-registry quay-pull-secret --docker-server=quay.io --docker-username="$quayrouser" --docker-password="$quayropass" --docker-email="$quayroemail" -n petclinic-dev -o json | kubeseal --cert ~/bitnami/publickey.pem > gitops/java/overlays/dev/quay-pull-sealedsecret.json
oc create secret docker-registry quay-pull-secret --docker-server=quay.io --docker-username="$quayrouser" --docker-password="$quayropass" --docker-email="$quayroemail" -n petclinic-uat -o json | kubeseal --cert ~/bitnami/publickey.pem > gitops/java/overlays/uat/quay-pull-sealedsecret.json

echo "Adding/Committing/Pushing to the $GIT_REF branch of $GIT_URL"
git add --all
git commit -m "Updated routes and git repo urls/branches."
git push origin $GIT_REF
echo "Pushed!"

echo "Done!"
