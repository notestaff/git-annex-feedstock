#!/bin/bash

set -e -o pipefail -x

export LIBRARY_PATH="${PREFIX}/lib:${LIBRARY_PTH}"
export LD_LIBRARY_PATH="${PREFIX}/lib:${LD_LIBRARY_PATH}"
export LDFLAGS=" -L${PREFIX}/lib ${LDFLAGS} "
export CPPFLAGS="-I${PREFIX}/include ${CPPFLAGS} "

export GMP_INCLUDE_DIRS=$PREFIX/include
export GMP_LIB_DIRS=$PREFIX/lib

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

rm ${BUILD_PREFIX}/${HOST}/sysroot/usr/lib/libpthread.so
ln -s /lib64/libpthread.so.0 ${BUILD_PREFIX}/${HOST}/sysroot/usr/lib/libpthread.so

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
