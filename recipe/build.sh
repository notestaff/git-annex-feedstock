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

echo "#!/bin/bash" > $CXX-shim
echo "set -e -o pipefail -x " >> $CXX-shim
echo "$CXX -I$PREFIX/include -L$PREFIX/lib -pthread -fPIC \"\$@\"" >> $CXX-shim
chmod u+x $CXX-shim
export CXX=$CXX-shim

echo "#!/bin/bash" > $GCC-shim
echo "set -e -o pipefail -x " >> $GCC-shim
echo "$GCC -I$PREFIX/include -L$PREFIX/lib -pthread -fPIC \"\$@\"" >> $GCC-shim
chmod u+x $GCC-shim
export GCC=$GCC-shim

echo "#!/bin/bash" > $GXX-shim
echo "set -e -o pipefail -x " >> $GXX-shim
echo "$GXX -I$PREFIX/include -L$PREFIX/lib -pthread -fPIC \"\$@\"" >> $GXX-shim
chmod u+x $GXX-shim
export GXX=$GXX-shim

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

HOST_LIBPTHREAD="${BUILD_PREFIX}/${HOST}/sysroot/usr/lib/libpthread.so"
rm ${HOST_LIBPTHREAD}
ln -s /lib64/libpthread.so.0 ${HOST_LIBPTHREAD}

mkdir -p ~/.stack
echo "extra-include-dirs:"  > ~/.stack/config.yaml
echo "- ${PREFIX}/include" >> ~/.stack/config.yaml
echo "extra-lib-dirs:"     >> ~/.stack/config.yaml
echo "- ${PREFIX}/lib"     >> ~/.stack/config.yaml
echo "ghc-options:"        >> ~/.stack/config.yaml
echo "  \"\$everything\": -optc-I${PREFIX}/include -optl-L${PREFIX}/lib" >> ~/.stack/config.yaml
echo "apply-ghc-options: everything" >> ~/.stack/config.yaml

stack setup
stack update
stack install --extra-include-dirs ${PREFIX}/include --extra-lib-dirs ${PREFIX}/lib --ghc-options " -optc-I${PREFIX}/include -optl-L${PREFIX}/lib " --local-bin-path ${PREFIX}/bin
ln -s ${PREFIX}/bin/git-annex ${PREFIX}/bin/git-annex-shell
