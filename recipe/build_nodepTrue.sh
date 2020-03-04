#!/bin/bash

set -e -o pipefail -x

BINARY_HOME=$PREFIX/bin
PACKAGE_HOME=$PREFIX/share/$PKG_NAME-$PKG_VERSION-$PKG_BUILDNUM

mkdir -p $BINARY_HOME
mkdir -p $PACKAGE_HOME

mv * ${PACKAGE_HOME}/
cp ${SRC_DIR}/git-annex-standalone-amd64.tar.gz_ ${PACKAGE_HOME}/git-annex-standalone-amd64.tar.gz
tar -C ${PACKAGE_HOME} -xvzf  ${PACKAGE_HOME}/git-annex-standalone-amd64.tar.gz
ln -s ${PACKAGE_HOME}/git-annex.linux/git-annex $PREFIX/bin/
ln -s ${PACKAGE_HOME}/git-annex.linux/git-annex-shell $PREFIX/bin/
