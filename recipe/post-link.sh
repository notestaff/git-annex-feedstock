#!/bin/bash

MSGS=$PREFIX/.messages.txt
touch $MSGS

function msg {
    echo $1 >> $MSGS 2>&1
}

msg "============================================================================================================="
msg "============= git-annex recently introduced changes that may break old workflows ============================"
msg "============================================================================================================="
msg "                                                                                                             "
msg "In short: the behavior of \"git add\" may be affected depending on your configuration.                       "
msg "                                                                                                             "
msg "If annex.largefiles is set then git add will add large files to the annex, not to git, unless you also set   "
msg "annex.gitaddtoannex=false .  Files added to the annex by git add will be in unlocked state.                  "
msg "v5 repos will be auto-upgraded to v7, unless you set annex.autoupgraderepository=false.                      "
msg "                                                                                                             "
msg "Please see https://hackage.haskell.org/package/git-annex-${PKG_VERSION}/changelog and                        "
msg "https://git-annex.branchable.com/news/version_${PKG_VERSION}/ for details of what changed.                   "
msg "                                                                                                             "
msg "============================================================================================================="
