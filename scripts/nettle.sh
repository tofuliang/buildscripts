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

mkdir -p _build$dir_suffix
cd _build$dir_suffix
if [ ! -f make.finished ];then
	../configure \
		--host=$ndk_triple \
		--enable-mini-gmp --disable-shared \
		--prefix="`pwd`/../../../prefix$dir_suffix"

	make -j$jobs && touch make.finished
fi
make install
# for ffmpeg:
cat >../../../prefix$dir_suffix/include/gmp.h <<'EOF'
#include <nettle/mini-gmp.h>
#define mpz_div_2exp(q,d,e) mpz_tdiv_q_2exp(q,d,e)
#define mpz_mod_2exp(q,d,e) mpz_tdiv_r_2exp(q,d,e)
EOF
[ -f ../../../prefix$dir_suffix/lib/libgmp.a ] && rm ../../../prefix$dir_suffix/lib/libgmp.a;
ln -sf libhogweed.a ../../../prefix$dir_suffix/lib/libgmp.a
