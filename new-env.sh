#!/bin/bash

read -p 'Base apps url (e.g. app.ocp.pitt.ca): ' APPS_BASE_URL
read -p 'Git repository url: ' GIT_URL
read -p 'Git branch (e.g. master): ' GIT_REF

FIND_ROUTE_PREFIX=$'find $PWD \\( -type d -name .git -prune \\) -o -type f -print0 | xargs -0 sed -i \'\' \'s/apps\\.example\\.com/'
FIND_REPO_PREFIX=$'find $PWD \\( -type d -name .git -prune \\) -o -type f -print0 | xargs -0 sed -i \'\' \'s/git\\.url\\.git/'
FIND_BRANCH_PREFIX=$'find $PWD \\( -type d -name .git -prune \\) -o -type f -print0 | xargs -0 sed -i \'\' \'s/targetRevision:\ master/targetRevision:\ '
FIND_SUFFIX=$'/g\''

ROUTE=$(sed 's/\./\\./g' <<< $APPS_BASE_URL)
REPO=$(sed 's/\./\\./g' <<< $GIT_URL)
REPO=$(sed 's/\//\\\//g' <<< $REPO)
BRANCH=$(sed 's/\./\\./g' <<< $GIT_REF)

FIND_AND_REPLACE_ROUTE=$FIND_ROUTE_PREFIX$ROUTE$FIND_SUFFIX
FIND_AND_REPLACE_REPO="$FIND_REPO_PREFIX$REPO$FIND_SUFFIX"
FIND_AND_REPLACE_BRANCH="$FIND_BRANCH_PREFIX$BRANCH$FIND_SUFFIX"

echo "About to execute: "
echo "$FIND_AND_REPLACE_ROUTE"
echo "$FIND_AND_REPLACE_REPO"
echo "$FIND_AND_REPLACE_BRANCH"
echo ""

eval $FIND_AND_REPLACE_ROUTE
eval $FIND_AND_REPLACE_REPO
eval $FIND_AND_REPLACE_BRANCH

echo "Done!"
