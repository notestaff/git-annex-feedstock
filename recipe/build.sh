#!/bin/bash

set -e -o pipefail -x

###################################################################################################################
# Set up the C/C++ compilation environment
###################################################################################################################

mkdir -p $PREFIX/bin $BUILD_PREFIX/bin $PREFIX/lib $BUILD_PREFIX/lib $PREFIX/share $BUILD_PREFIX/share
export LIBRARY_PATH="${PREFIX}/lib:${LIBRARY_PTH}"
export LD_LIBRARY_PATH="${PREFIX}/lib:${LD_LIBRARY_PATH}"
export LDFLAGS=" -L${PREFIX}/lib ${LDFLAGS} "
export CPPFLAGS="-I${PREFIX}/include ${CPPFLAGS} "

export GMP_INCLUDE_DIRS=$PREFIX/include
export GMP_LIB_DIRS=$PREFIX/lib

# Ugly hack 1: ensure that the C/C++ compiler and linker are always called with certain flags.
# We install shim scripts that call the original compiler/linker after prepending the flags to the command line.
# My efforts to do this by standard methods, via configure flags, have been unsuccessful: there was always some
# case where the flags would not get passed down to the compiler/linker.

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

# Ugly hack 2: replace libpthread with the system one.
# We want to link against /lib64/libpthread .  But some compilations stubbornly try to link
# against ${BUILD_PREFIX}/${HOST}/sysroot/usr/lib/libpthread.so which currently forwards to
# /lib/libpthread which is 32-bit, when we need 64-bit.  The hack below seems to make things
# work, but of course a better solution is needed.

LIBPTHREAD_SO="${BUILD_PREFIX}/${HOST}/sysroot/usr/lib/libpthread.so"
rm ${LIBPTHREAD_SO}
ln -s ${LIBPTHREAD_SO}

###################################################################################################################
# Set up bootstrap GHC
###################################################################################################################

export GHC_BOOTSTRAP_PREFIX=${SRC_DIR}/ghc_bootstrap_pfx
mkdir -p $GHC_BOOTSTRAP_PREFIX/bin
export PATH=$PATH:${GHC_BOOTSTRAP_PREFIX}/bin

pushd ${SRC_DIR}/ghc_bootstrap
./configure --prefix=${GHC_BOOTSTRAP_PREFIX}
make install
ghc-pkg recache
popd

###################################################################################################################
# Build recent GHC from source, using bootstrap GHC
###################################################################################################################

pushd ${SRC_DIR}/ghc_src

touch mk/build.mk
echo "HADDOCK_DOCS = NO" >> mk/build.mk
echo "BuildFlavour = quick" >> mk/build.mk
echo "libraries/integer-gmp_CONFIGURE_OPTS += --configure-option=--with-gmp-includes=$PREFIX/include" >> mk/build.mk
echo "libraries/integer-gmp_CONFIGURE_OPTS += --configure-option=--with-gmp-libraries=$PREFIX/lib" >> mk/build.mk
echo "STRIP_CMD = $STRIP" >> build.mk

./boot
./configure --prefix=${BUILD_PREFIX}  --with-gmp-includes=$PREFIX/include --with-gmp-libraries=$PREFIX/libraries
set +e
make -j${CPU_COUNT}
set -e
make
make install
ghc-pkg recache
popd

###################################################################################################################
# Finally, build git-annex using the recent GHC
###################################################################################################################

pushd ${SRC_DIR}/git_annex_main

mkdir -p ~/.stack
echo "extra-include-dirs:"  > ~/.stack/config.yaml
echo "- ${PREFIX}/include" >> ~/.stack/config.yaml
echo "extra-lib-dirs:"     >> ~/.stack/config.yaml
echo "- ${PREFIX}/lib"     >> ~/.stack/config.yaml
echo "ghc-options:"        >> ~/.stack/config.yaml
echo "  \"\$everything\": -optc-I${PREFIX}/include -optl-L${PREFIX}/lib" >> ~/.stack/config.yaml
echo "apply-ghc-options: everything" >> ~/.stack/config.yaml

stack --system-ghc setup
stack --system-ghc update
stack --system-ghc install --extra-include-dirs ${PREFIX}/include --extra-lib-dirs ${PREFIX}/lib --ghc-options " -optc-I${PREFIX}/include -optl-L${PREFIX}/lib " --local-bin-path ${PREFIX}/bin
ln -s ${PREFIX}/bin/git-annex ${PREFIX}/bin/git-annex-shell
popd
