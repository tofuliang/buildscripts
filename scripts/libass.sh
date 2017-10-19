#!/bin/bash -e

. ../../path.sh

if [ "$1" == "build" ]; then
	true
elif [ "$1" == "clean" ]; then
	rm -rf _build$dir_suffix && [ -f make.finished ] && rm make.finished
	exit 0
else
	exit 255
fi

[ -f configure ] || ./autogen.sh

mkdir -p _build$dir_suffix
cd _build$dir_suffix
if [ ! -f make.finished ];then
	PKG_CONFIG_LIBDIR="`pwd`/../../../prefix$dir_suffix/lib/pkgconfig" \
	../configure \
		--host=$ndk_triple \
		--enable-static --disable-shared \
		--disable-require-system-font-provider \
		--prefix="`pwd`/../../../prefix$dir_suffix"

	make -j$jobs && touch make.finished
fi
make install
