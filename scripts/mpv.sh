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

[ -f waf ] || ./bootstrap.py

extrald=
[[ "$ndk_triple" == "aarch64"* ]] && extrald="-fuse-ld=gold"
if [ ! -f make.finished ];then
	PKG_CONFIG_LIBDIR="`pwd`/../../prefix$dir_suffix/lib/pkgconfig" \
	LDFLAGS="$extrald" \
	./waf configure \
		--disable-iconv --lua=52 \
		--enable-libmpv-shared \
		--prefix=/ --disable-manpage-build \
		-o "`pwd`/_build$dir_suffix"

	./waf build -p -j$jobs && touch make.finished
fi
./waf install --destdir="`pwd`/../../prefix$dir_suffix"
