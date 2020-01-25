#!/bin/bash

read -p 'Base apps url (e.g. app.ocp.pitt.ca): ' APPS_BASE_URL
read -p 'Git repository url: ' GIT_URL
read -p 'Git branch (e.g. master): ' GIT_REF
read -p 'Quay read/write username: ' quayrwuser
read -p 'Quay reqd/write email: ' quayrwemail
read -sp 'Quay read/write password: ' quayrwpass
read -p 'Quay read-only username: ' quayrouser
read -p 'Quay read-only email: ' quayroemail
read -sp 'Quay read-only password: ' quayropass

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

echo "Creting Sealed Secrets."
kubeseal --cert ~/kubeseal.pem <blah.json >/gitops/cicd/builds/quay-creds-sealed-secret.json
kubeseal --cert ~/kubeseal.pem <blah2.json >/gitops/java/petclinic/overlays/dev/quay-readonly-sealed-secret.json
kubeseal --cert ~/kubeseal.pem <blah3.json >/gitops/java/petclinic/overlays/dev/quay-readonly-sealed-secret.json

echo "Done!"
