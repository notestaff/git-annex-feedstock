#!/bin/sh

set -eu -o pipefail -x

BINARY_HOME=${PREFIX}/bin
export PACKAGE_HOME=${PREFIX}/share/${PKG_NAME}-${PKG_VERSION}-${PKG_BUILDNUM}

mkdir -p ${BINARY_HOME} ${PACKAGE_HOME}

mv git-annex-${PKG_VERSION}.tar.gz_ git-annex-${PKG_VERSION}.tar.gz
tar xvfz git-annex-${PKG_VERSION}.tar.gz --directory ${PACKAGE_HOME}

cp ${PACKAGE_HOME}/git-annex.linux/LICENSE .

pushd ${PACKAGE_HOME}/git-annex.linux
patch < ${RECIPE_DIR}/0001-fix-locpath.patch
popd

export GIT_ANNEX_LOCPATH=${PACKAGE_HOME}/locpath
mkdir -p ${GIT_ANNEX_LOCPATH}
${PACKAGE_HOME}/git-annex.linux/runshell ls

# FAKE_HOME=${PACKAGE_HOME}/home
# mkdir -p ${PACKAGE_HOME}/home
# HOME=${FAKE_HOME} ${PACKAGE_HOME}/git-annex.linux/runshell ls
# NEW_LOC_DIR=$(ls -d ${FAKE_HOME}/.cache/git-annex/locales/*)
# mv ${NEW_LOC_DIR} ${PACKAGE_HOME}/locales

echo "#!/bin/sh" > ${BINARY_HOME}/git-annex
echo "" >> ${BINARY_HOME}/git-annex
echo "set -eux -o pipefail" >> ${BINARY_HOME}/git-annex
echo "export LOCPATH=${GIT_ANNEX_LOCPATH}" >> ${BINARY_HOME}/git-annex
#echo "export GIT_ANNEX_PACKAGE_INSTALL=1" >> ${BINARY_HOME}/git-annex
echo "${PACKAGE_HOME}/git-annex.linux/runshell git-annex \"\$@\"" >> ${BINARY_HOME}/git-annex
chmod u+x ${BINARY_HOME}/git-annex
