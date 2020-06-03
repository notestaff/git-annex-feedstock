#!/bin/bash

set -e -o pipefail -x

#######################################################################################################
# Set up build environment
#######################################################################################################

mkdir -p $PREFIX/bin $BUILD_PREFIX/bin $PREFIX/lib $BUILD_PREFIX/lib $PREFIX/share $BUILD_PREFIX/share
export LIBRARY_PATH="${PREFIX}/lib:${LIBRARY_PATH}"
export LD_LIBRARY_PATH="${PREFIX}/lib:${LD_LIBRARY_PATH}"
export LDFLAGS=" -L${PREFIX}/lib ${LDFLAGS} "
export CPPFLAGS="-I${PREFIX}/include ${CPPFLAGS} "

export GMP_INCLUDE_DIRS=$PREFIX/include
export GMP_LIB_DIRS=$PREFIX/lib

#
# Install shim scripts to ensure that certain flags are always passed to the compiler/linker
#

echo "#!/bin/bash" > $CC-shim
echo "set -e -o pipefail -x " >> $CC-shim
echo "$CC -I$PREFIX/include -L$PREFIX/lib -pthread -fPIC \"\$@\"" >> $CC-shim
chmod u+x $CC-shim
export CC=$CC-shim

echo "#!/bin/bash" > $GCC-shim
echo "set -e -o pipefail -x " >> $GCC-shim
echo "$GCC -I$PREFIX/include -L$PREFIX/lib -pthread -fPIC \"\$@\"" >> $GCC-shim
chmod u+x $GCC-shim
export GCC=$GCC-shim

echo "#!/bin/bash" > $LD-shim
echo "set -e -o pipefail -x " >> $LD-shim
echo "$LD -L$PREFIX/lib \"\$@\"" >> $LD-shim
chmod u+x $LD-shim
export LD=$LD-shim

echo "#!/bin/bash" > ${LD}.gold
echo "set -e -o pipefail -x " >> ${LD}.gold
echo "$LD_GOLD -L$PREFIX/lib \"\$@\"" >> ${LD}.gold
chmod u+x ${LD}.gold
export LD_GOLD=${LD}.gold

#
# Hack: ensure that the correct libpthread is used.
# This fixes an issue specific to https://github.com/conda-forge/docker-images/tree/master/linux-anvil-comp7
# which I do not fully understand, but the fix seems to work.
# See https://github.com/conda/conda/issues/8380
#

HOST_LIBPTHREAD="${BUILD_PREFIX}/${HOST}/sysroot/usr/lib/libpthread.so"

if [[ -f "${HOST_LIBPTHREAD}" ]]; then
    rm ${HOST_LIBPTHREAD}
    ln -s /lib64/libpthread.so.0 ${HOST_LIBPTHREAD}
fi

#######################################################################################################
# Install bootstrap ghc
#######################################################################################################

export GHC_BOOTSTRAP_PREFIX=${SRC_DIR}/ghc_bootstrap_pfx
mkdir -p $GHC_BOOTSTRAP_PREFIX/bin
export PATH=$PATH:${GHC_BOOTSTRAP_PREFIX}/bin

pushd ${SRC_DIR}/ghc_bootstrap
./configure --prefix=${GHC_BOOTSTRAP_PREFIX}
make install
ghc-pkg recache

popd

#######################################################################################################
# Build recent ghc from source
#######################################################################################################

# pushd ${SRC_DIR}/ghc_src

# touch mk/build.mk
# echo "HADDOCK_DOCS = NO" >> mk/build.mk
# echo "BuildFlavour = quick" >> mk/build.mk
# echo "libraries/integer-gmp_CONFIGURE_OPTS += --configure-option=--with-gmp-includes=$PREFIX/include" >> mk/build.mk
# echo "libraries/integer-gmp_CONFIGURE_OPTS += --configure-option=--with-gmp-libraries=$PREFIX/lib" >> mk/build.mk
# echo "STRIP_CMD = $STRIP" >> build.mk

# echo "========CHECKING FREE SPACE==========="
# df .

# ./boot
# ./configure --prefix=${BUILD_PREFIX}  --with-gmp-includes=$PREFIX/include --with-gmp-libraries=$PREFIX/lib --with-system-libffi
# set +e
# echo "========BUILING GHC FROM SOURCE, multi-cpu==========="
# df .
# make -j${CPU_COUNT}
# df .
# echo "========DONE BUILING GHC FROM SOURCE, multi-cpu==========="
# set -e
# echo "========BUILING GHC FROM SOURCE, one-cpu==========="
# df .
# make
# df .
# echo "========DONE BUILING GHC FROM SOURCE, one-cpu==========="
# echo "========INSTALLING GHC==========="
# df .
# make install
# df .
# echo "========CLEANING GHC==========="
# make clean
# df .
# echo "========RECACHING==========="
# ghc-pkg recache
# echo "========DONE RECACHING==========="
# df .
# echo "========SPACE USAGE AFTER RECACHING==========="
# pwd
# du -hs .
# popd

#######################################################################################################
# Build git-annex
#######################################################################################################

pushd ${SRC_DIR}/git_annex_main

export STACK_ROOT=${SRC_DIR}/stack_root
mkdir -p $STACK_ROOT
( 
    echo "extra-include-dirs:"
    echo "- ${PREFIX}/include"
    echo "extra-lib-dirs:"
    echo "- ${PREFIX}/lib"
    echo "ghc-options:"
    echo "  \"\$everything\": -optc-I${PREFIX}/include -optl-L${PREFIX}/lib"
    echo "apply-ghc-options: everything"
    echo "compiler: ghc-git-92b6a0237e0195cee4773de4b237951addd659d9-quick"
#    echo "system-ghc: true"
) > "${STACK_ROOT}/config.yaml"

stack setup --compiler ghc-git-92b6a0237e0195cee4773de4b237951addd659d9-quick
stack update --compiler ghc-git-92b6a0237e0195cee4773de4b237951addd659d9-quick
stack install --compiler ghc-git-92b6a0237e0195cee4773de4b237951addd659d9-quick --extra-include-dirs ${PREFIX}/include --extra-lib-dirs ${PREFIX}/lib --ghc-options " -optc-I${PREFIX}/include -optl-L${PREFIX}/lib " --local-bin-path ${PREFIX}/bin # --flag git-annex:magicmime --flag git-annex:dbus
ln -s ${PREFIX}/bin/git-annex ${PREFIX}/bin/git-annex-shell
popd

