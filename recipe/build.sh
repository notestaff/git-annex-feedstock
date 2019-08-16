#!/bin/bash

set -e -o pipefail -x

echo "STARTING GIT-ANNEX BUILD; env is"
env

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

echo "BEFORE INSTALLING SHIM SCRIPTS; env is"
env

#
# Install shim scripts to ensure that certain flags are always passed to the compiler/linker
#

# if [ -n "${CC:+1}" ]; then
#     export CC=$(realpath "$CC")
#     echo "#!/bin/bash" > $CC-shim
#     echo "set -e -o pipefail -x " >> $CC-shim
#     echo "$CC -I$PREFIX/include -L$PREFIX/lib -pthread -fPIC \"\$@\"" >> $CC-shim
#     chmod u+x $CC-shim
#     export CC=$CC-shim
# fi

# if [ -n "${CXX:+1}" ]; then
#     export CXX=$(realpath "$CXX")
#     echo "#!/bin/bash" > $CXX-shim
#     echo "set -e -o pipefail -x " >> $CXX-shim
#     echo "$CXX -I$PREFIX/include -L$PREFIX/lib -pthread -fPIC \"\$@\"" >> $CXX-shim
#     chmod u+x $CXX-shim
#     export CXX=$CXX-shim
# fi

# if [ -n "${GCC:+1}" ]; then
#     export GCC=$(realpath "$GCC")
#     echo "#!/bin/bash" > $GCC-shim
#     echo "set -e -o pipefail -x " >> $GCC-shim
#     echo "$GCC -I$PREFIX/include -L$PREFIX/lib -pthread -fPIC \"\$@\"" >> $GCC-shim
#     chmod u+x $GCC-shim
#     export GCC=$GCC-shim
# fi

# if [ -n "${GXX:+1}" ]; then
#     export GXX=$(realpath "$GXX")
#     echo "#!/bin/bash" > $GXX-shim
#     echo "set -e -o pipefail -x " >> $GXX-shim
#     echo "$GXX -I$PREFIX/include -L$PREFIX/lib -pthread -fPIC \"\$@\"" >> $GXX-shim
#     chmod u+x $GXX-shim
#     export GXX=$GXX-shim
# fi

# if [ -n "${LD:+1}" ]; then
#     export LD=$(realpath "$LD")
#     echo "#!/bin/bash" > $LD-shim
#     echo "set -e -o pipefail -x " >> $LD-shim
#     echo "$LD -L$PREFIX/lib \"\$@\"" >> $LD-shim
#     chmod u+x $LD-shim
#     export LD=$LD-shim
# fi

# if [ -n "${LD_GOLD:+1}" ]; then
#     export LD_GOLD=$(realpath "${LD_GOLD}")
#     echo "#!/bin/bash" > ${LD}.gold
#     echo "set -e -o pipefail -x " >> ${LD}.gold
#     echo "$LD_GOLD -L$PREFIX/lib \"\$@\"" >> ${LD}.gold
#     chmod u+x ${LD}.gold
#     export LD_GOLD=${LD}.gold
# fi

echo "AFTER INSTALLING SHIM SCRIPTS; env is"
env

#
# Hack: ensure that the correct libpthread is used
#

HOST_LIBPTHREAD="${BUILD_PREFIX}/${HOST}/sysroot/usr/lib/libpthread.so"

if [[ -f "${HOST_LIBPTHREAD}" ]]; then
    rm ${HOST_LIBPTHREAD}
    ln -s /lib64/libpthread.so.0 ${HOST_LIBPTHREAD}
fi

# #######################################################################################################
# # Install bootstrap ghc
# #######################################################################################################

# export GHC_BOOTSTRAP_PREFIX=${SRC_DIR}/ghc_bootstrap_pfx
# mkdir -p $GHC_BOOTSTRAP_PREFIX/bin
# export PATH=$PATH:${GHC_BOOTSTRAP_PREFIX}/bin

# pushd ${SRC_DIR}/ghc_bootstrap
# ./configure --prefix=${GHC_BOOTSTRAP_PREFIX}  || cat config.log
# make install
# ghc-pkg recache

# popd

# #######################################################################################################
# # Build recent ghc from source
# #######################################################################################################

# pushd ${SRC_DIR}/ghc_src

# touch mk/build.mk
# echo "HADDOCK_DOCS = NO" >> mk/build.mk
# echo "BuildFlavour = quick" >> mk/build.mk
# echo "libraries/integer-gmp_CONFIGURE_OPTS += --configure-option=--with-gmp-includes=$PREFIX/include" >> mk/build.mk
# echo "libraries/integer-gmp_CONFIGURE_OPTS += --configure-option=--with-gmp-libraries=$PREFIX/lib" >> mk/build.mk
# echo "STRIP_CMD = $STRIP" >> build.mk

# ./boot
# ./configure --prefix=${BUILD_PREFIX}  --with-gmp-includes=$PREFIX/include --with-gmp-libraries=$PREFIX/libraries --with-system-libffi
# set +e
# make -j${CPU_COUNT}
# set -e
# make
# make install
# ghc-pkg recache
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
    echo "  \"\$everything\": -v -optc-I${PREFIX}/include -optl-L${PREFIX}/lib"
    echo "apply-ghc-options: everything"
#    echo "system-ghc: true"
) > "${STACK_ROOT}/config.yaml"

stack setup --verbose
stack update
stack install --extra-include-dirs ${PREFIX}/include --extra-lib-dirs ${PREFIX}/lib --ghc-options " -optc-I${PREFIX}/include -optl-L${PREFIX}/lib " --local-bin-path ${PREFIX}/bin --flag git-annex:magicmime --flag git-annex:dbus
ln -s ${PREFIX}/bin/git-annex ${PREFIX}/bin/git-annex-shell
popd
