#!/bin/bash

set -e -o pipefail -x

export LIBRARY_PATH="${PREFIX}/lib:${LIBRARY_PTH}"
export LD_LIBRARY_PATH="${PREFIX}/lib:${LD_LIBRARY_PATH}"
export LDFLAGS=" -L${PREFIX}/lib ${LDFLAGS} "
export CPPFLAGS="-I${PREFIX}/include ${CPPFLAGS} "

export GMP_INCLUDE_DIRS=$PREFIX/include
export GMP_LIB_DIRS=$PREFIX/lib

# echo "#!/bin/bash" > $CC-shim
# echo "set -e -o pipefail -x " >> $CC-shim
# echo "$CC -I$PREFIX/include -L$PREFIX/lib -pthread -fPIC \"\$@\"" >> $CC-shim
# chmod u+x $CC-shim
# export CC=$CC-shim

# echo "#!/bin/bash" > $CXX-shim
# echo "set -e -o pipefail -x " >> $CXX-shim
# echo "$CXX -I$PREFIX/include -L$PREFIX/lib -pthread -fPIC \"\$@\"" >> $CXX-shim
# chmod u+x $CXX-shim
# export CXX=$CXX-shim


# if [ -z ${GCC+x} ];
# then
#     echo "GCC is unset"
# else
#     echo "#!/bin/bash" > $GCC-shim
#     echo "set -e -o pipefail -x " >> $GCC-shim
#     echo "$GCC -I$PREFIX/include -L$PREFIX/lib -pthread -fPIC \"\$@\"" >> $GCC-shim
#     chmod u+x $GCC-shim
#     export GCC=$GCC-shim
# fi

# if [ -z ${GXX+x} ];
# then
#     echo "GXX is unset"
# else
#     echo "#!/bin/bash" > $GXX-shim
#     echo "set -e -o pipefail -x " >> $GXX-shim
#     echo "$GXX -I$PREFIX/include -L$PREFIX/lib -pthread -fPIC \"\$@\"" >> $GXX-shim
#     chmod u+x $GXX-shim
#     export GXX=$GXX-shim
# fi

# echo "#!/bin/bash" > $LD-shim
# echo "set -e -o pipefail -x " >> $LD-shim
# echo "$LD -L$PREFIX/lib \"\$@\"" >> $LD-shim
# chmod u+x $LD-shim
# export LD=$LD-shim

# echo "#!/bin/bash" > ${LD}.gold
# echo "set -e -o pipefail -x " >> ${LD}.gold
# echo "$LD_GOLD -L$PREFIX/lib \"\$@\"" >> ${LD}.gold
# chmod u+x ${LD}.gold
# export LD_GOLD=${LD}.gold

# LIBPTHREAD_SO="${BUILD_PREFIX}/${HOST}/sysroot/usr/lib/libpthread.so"
# if [ -f "${LIBPTHREAD_SO}" ];
# then
#     rm ${LIBPTHREAD_SO}
#     ln -s /lib64/libpthread.so.0 ${LIBPTHREAD_SO}
# fi

mkdir -p ~/.stack
echo "extra-include-dirs:"  > ~/.stack/config.yaml
echo "- ${PREFIX}/include" >> ~/.stack/config.yaml
echo "extra-lib-dirs:"     >> ~/.stack/config.yaml
echo "- ${PREFIX}/lib"     >> ~/.stack/config.yaml
echo "ghc-options:"        >> ~/.stack/config.yaml
echo "  \"\$everything\": -optc-I${PREFIX}/include -optl-L${PREFIX}/lib" >> ~/.stack/config.yaml
echo "apply-ghc-options: everything" >> ~/.stack/config.yaml

stack --verbose setup
stack --verbose update
stack --verbose install --extra-include-dirs ${PREFIX}/include --extra-lib-dirs ${PREFIX}/lib --ghc-options " -optc-I${PREFIX}/include -optl-L${PREFIX}/lib " --local-bin-path ${PREFIX}/bin
ln -s ${PREFIX}/bin/git-annex ${PREFIX}/bin/git-annex-shell
