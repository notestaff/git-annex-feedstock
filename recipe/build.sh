#!/bin/bash

set -e -o pipefail -x

export LIBRARY_PATH="${PREFIX}/lib"
export LD_LIBRARY_PATH="${PREFIX}/lib"
export LDFLAGS="  -L${PREFIX}/lib"
export CPPFLAGS="-I${PREFIX}/include"

export GMP_INCLUDE_DIRS=$PREFIX/include
export GMP_LIB_DIRS=$PREFIX/lib

echo "#!/bin/bash" > $CC-mine
echo "set -e -o pipefail -x " >> $CC-mine
echo "$CC -I$PREFIX/include   -L$PREFIX/lib -pthread -fPIC \"\$@\"" >> $CC-mine
chmod u+x $CC-mine
export CC=$CC-mine

echo "#!/bin/bash" > $CXX-mine
echo "set -e -o pipefail -x " >> $CXX-mine
echo "$CXX -I$PREFIX/include   -L$PREFIX/lib -pthread -fPIC \"\$@\"" >> $CXX-mine
chmod u+x $CXX-mine
export CXX=$CXX-mine

echo "#!/bin/bash" > $GCC-mine
echo "set -e -o pipefail -x " >> $GCC-mine
echo "$GCC -I$PREFIX/include   -L$PREFIX/lib -pthread -fPIC \"\$@\"" >> $GCC-mine
chmod u+x $GCC-mine
export GCC=$GCC-mine

echo "#!/bin/bash" > $GXX-mine
echo "set -e -o pipefail -x " >> $GXX-mine
echo "$GXX -I$PREFIX/include   -L$PREFIX/lib -pthread -fPIC \"\$@\"" >> $GXX-mine
chmod u+x $GXX-mine
export GXX=$GXX-mine

echo "#!/bin/bash" > $LD-mine
echo "set -e -o pipefail -x " >> $LD-mine
echo "$LD   -L$PREFIX/lib  \"\$@\"" >> $LD-mine
chmod u+x $LD-mine
export LD=$LD-mine

echo "#!/bin/bash" > ${LD}.gold
echo "set -e -o pipefail -x " >> ${LD}.gold
echo "$LD_GOLD   -L$PREFIX/lib  \"\$@\"" >> ${LD}.gold
chmod u+x ${LD}.gold
export LD_GOLD=${LD}.gold

rm ${BUILD_PREFIX}/${HOST}/sysroot/usr/lib/libpthread.so
ln -s /lib64/libpthread.so.0 ${BUILD_PREFIX}/${HOST}/sysroot/usr/lib/libpthread.so

mkdir -p ~/.stack
echo "extra-include-dirs:"  > ~/.stack/config.yaml
echo "- ${PREFIX}/include" >> ~/.stack/config.yaml
echo "extra-lib-dirs:" >> ~/.stack/config.yaml
echo "- ${PREFIX}/lib" >> ~/.stack/config.yaml
echo "ghc-options:" >> ~/.stack/config.yaml
echo "  \"\$everything\": -optc-I${PREFIX}/include -optl-L${PREFIX}/lib" >> ~/.stack/config.yaml
echo "apply-ghc-options: everything" >> ~/.stack/config.yaml

stack setup
stack update
stack install --extra-include-dirs ${PREFIX}/include --extra-lib-dirs ${PREFIX}/lib --ghc-options " -optc-I${PREFIX}/include -optl-L${PREFIX}/lib "  --local-bin-path ${PREFIX}/bin
ln -s ${PREFIX}/bin/git-annex ${PREFIX}/bin/git-annex-shell
