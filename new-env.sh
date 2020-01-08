#!/bin/bash

FIND_PREFIX=$'find $PWD \\( -type d -name .git -prune \\) -o -type f -print0 | xargs -0 sed -i \'\' \'s/apps\\.example\\.com/'
FIND_SUFFIX=$'/g\''

ROUTE=$(sed 's/\./\\\\./g' <<< $1)

#FIND_ROUTE=$'find $PWD \\( -type d -name .git -prune \\) -o -type f -print0 | xargs -0 sed -i \'\' \'s/apps\\.example\\.com/apps\\.mycluster\\.com/g\''
FIND_ROUTE="$FIND_PREFIX$ROUTE$FIND_SUFFIX"

echo $FIND_ROUTE