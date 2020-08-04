#!/bin/bash

set -e -o pipefail -x

BINARY_HOME=$PREFIX/bin
PACKAGE_HOME=$PREFIX/share/$PKG_NAME-$PKG_VERSION-$PKG_BUILDNUM

mkdir -p $BINARY_HOME
mkdir -p $PACKAGE_HOME

mv * ${PACKAGE_HOME}/
ln -s ${PACKAGE_HOME}/git-annex $PREFIX/bin/
ln -s ${PACKAGE_HOME}/git-annex-shell $PREFIX/bin/

echo $PATH
which git-annex
git-annex version

