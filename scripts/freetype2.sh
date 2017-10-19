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

[ -f builds/unix/configure ] || ./autogen.sh

mkdir -p _build$dir_suffix
cd _build$dir_suffix

if [ ! -f make.finished ];then
	PKG_CONFIG=/bin/false \
	../configure \
		--host=$ndk_triple \
		--enable-static --disable-shared \
		--with-png=no \
		--prefix="`pwd`/../../../prefix$dir_suffix"
	make -j$jobs && touch make.finished
fi
make install
