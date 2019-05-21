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

if [ -z ${CC+x} ]
then
    echo CC is not set
else    
    echo "#!/bin/bash" > $CC-shim
    echo "set -e -o pipefail -x " >> $CC-shim
    echo "$CC -I$PREFIX/include -L$PREFIX/lib -pthread -fPIC \"\$@\"" >> $CC-shim
    chmod u+x $CC-shim
    export CC=$CC-shim
fi


if [ -z ${CXX+x} ]
then
    echo CXX is not set
else    
    echo "#!/bin/bash" > $CXX-shim
    echo "set -e -o pipefail -x " >> $CXX-shim
    echo "$CXX -I$PREFIX/include -L$PREFIX/lib -pthread -fPIC \"\$@\"" >> $CXX-shim
    chmod u+x $CXX-shim
    export CXX=$CXX-shim
fi

if [ -z ${GCC+x} ]
then
    echo GCC is not set
else    
    echo "#!/bin/bash" > $GCC-shim
    echo "set -e -o pipefail -x " >> $GCC-shim
    echo "$GCC -I$PREFIX/include -L$PREFIX/lib -pthread -fPIC \"\$@\"" >> $GCC-shim
    chmod u+x $GCC-shim
    export GCC=$GCC-shim
fi

if [ -z ${GXX+x} ]
then
    echo GXX is not set
else    
    echo "#!/bin/bash" > $GXX-shim
    echo "set -e -o pipefail -x " >> $GXX-shim
    echo "$GXX -I$PREFIX/include -L$PREFIX/lib -pthread -fPIC \"\$@\"" >> $GXX-shim
    chmod u+x $GXX-shim
    export GXX=$GXX-shim
fi

if [ -z ${LD+x} ]
then
    echo LD is not set
else    
    echo "#!/bin/bash" > $LD-shim
    echo "set -e -o pipefail -x " >> $LD-shim
    echo "$LD -L$PREFIX/lib \"\$@\"" >> $LD-shim
    chmod u+x $LD-shim
    export LD=$LD-shim
fi

if [ -z ${LD_GOLD+x} ]
then
    echo LD_GOLD is not set
else    
    echo "#!/bin/bash" > ${LD}.gold
    echo "set -e -o pipefail -x " >> ${LD}.gold
    echo "$LD_GOLD -L$PREFIX/lib \"\$@\"" >> ${LD}.gold
    chmod u+x ${LD}.gold
    export LD_GOLD=${LD}.gold
fi

HOST_LIBPTHREAD="${BUILD_PREFIX}/${HOST}/sysroot/usr/lib/libpthread.so"
if [ -f "${HOST_LIBPTHREAD}" ]; then
    rm ${HOST_LIBPTHREAD}
    ln -s /lib64/libpthread.so.0 ${HOST_LIBPTHREAD}
fi

#######################################################################################################
# Build git-annex
#######################################################################################################

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
) > "${STACK_ROOT}/config.yaml"

cp ${RECIPE_DIR}/git_annex_custom_snapshot.yaml .
stack --verbose setup --resolver git_annex_custom_snapshot.yaml
stack --verbose update --resolver git_annex_custom_snapshot.yaml
stack --verbose install --resolver git_annex_custom_snapshot.yaml --extra-include-dirs ${PREFIX}/include --extra-lib-dirs ${PREFIX}/lib --ghc-options " -optc-I${PREFIX}/include -optl-L${PREFIX}/lib " --local-bin-path ${PREFIX}/bin --flag git-annex:magicmime --flag git-annex:dbus
ln -s ${PREFIX}/bin/git-annex ${PREFIX}/bin/git-annex-shell
echo "SUCCESSFULLY BUILT git-annex in ${PREFIX}"

