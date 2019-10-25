#!/bin/bash

MSGS=$PREFIX/.messages.txt
touch $MSGS

function msg {
    echo $1 >> $MSGS 2>&1
}

msg
msg '============= This git-annex version introduces breaking changes  ==========================================='
msg 'In short: the behavior of "git add" may be affected depending on your configuration.                         '
msg 'Please see https://git-annex.branchable.com/news/version_${PKG_VERSION}/ for details of what changed.        '
msg '============================================================================================================='


