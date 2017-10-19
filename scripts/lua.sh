#!/bin/bash -e

. ../../path.sh

if [ "$1" == "build" ]; then
	true
elif [ "$1" == "clean" ]; then
	make clean && [ -f make.finished ] && rm make.finished
	exit 0
else
	exit 255
fi

# Building seperately from source tree is not supported, this means we are forced to always clean
$0 clean

# LUA_T= and LUAC_T= disable building lua & luac
# -Dgetlocaledecpoint()=('.') fixes bionic missing decimal_point in localeconv
if [ ! -f make.finished ];then
	make CC="$CC -Dgetlocaledecpoint\(\)=\(\'.\'\)" \
		AR="$ndk_triple-ar r" \
		RANLIB="$ndk_triple-ranlib" \
		PLAT=linux LUA_T= LUAC_T= -j$jobs && touch make.finished
fi
INSTALL=install
[ "$os" == "macosx" ] && INSTALL=ginstall

# TO_BIN=/dev/null disables installing lua & luac
make INSTALL="$INSTALL" INSTALL_TOP=`pwd`/../../prefix$dir_suffix TO_BIN=/dev/null install

# make pc only generates a partial pkg-config file because ????
mkdir -p ../../prefix$dir_suffix/lib/pkgconfig
make INSTALL_TOP=`pwd`/../../prefix pc > ../../prefix$dir_suffix/lib/pkgconfig/lua.pc
cat >>../../prefix$dir_suffix/lib/pkgconfig/lua.pc <<'EOF'
Name: Lua
Description:
Version: ${version}
Libs: -L${libdir} -llua
Cflags: -I${includedir}
EOF
