#!/bin/bash -e

v_sdk=r24.4.1
v_ndk=r15c
v_lua=5.2.4
v_fribidi=0.19.7
v_gnutls=3.6.0
v_nettle=3.3

. ./path.sh # load $os var

if [ "$os" == "linux" ]; then
	# get 32bit deps
	hash yum &> /dev/null && sudo yum install zlib.i686 ncurses-libs.i686 bzip2-libs.i686
	apt-get -v &> /dev/null && sudo apt-get install lib32z1 lib32ncurses5 lib32stdc++6

	sdk_ext="tgz"
	os_ndk="linux"
elif [ "$os" == "macosx" ]; then
	if hash brew 2>/dev/null; then
 		brew install automake autoconf libtool coreutils
 	else
 		echo "Error: brew not found. You need to install homebrew. http://brew.sh"
 		exit 255
	fi	
 	# get osx deps for building from brew
	sdk_ext="zip"
	os_ndk="darwin"
fi

mkdir -p sdk && cd sdk

# android-sdk-linux
if [ "$os" == "linux" ]; then
	wget "http://dl.google.com/android/android-sdk_${v_sdk}-${os}.${sdk_ext}" -O - | \
		tar -xz -f -
elif [ "$os" == "macosx" ]; then
	wget "http://dl.google.com/android/android-sdk_${v_sdk}-${os}.${sdk_ext}"
	unzip "android-sdk_${v_sdk}-${os}.${sdk_ext}"
	rm "android-sdk_${v_sdk}-${os}.${sdk_ext}"
fi
"./android-sdk-${os}/tools/android" update sdk --no-ui --all --filter build-tools-23.0.3,android-23,extra-android-m2repository

# android-ndk-$v_ndk
wget "http://dl.google.com/android/repository/android-ndk-${v_ndk}-${os_ndk}-x86_64.zip"
unzip "android-ndk-${v_ndk}-${os_ndk}-x86_64.zip"
rm "android-ndk-${v_ndk}-${os_ndk}-x86_64.zip"

# ndk-toolchain
cd "android-ndk-${v_ndk}"
toolchain_api=21
./build/tools/make_standalone_toolchain.py \
	--arch arm --api $toolchain_api \
	--install-dir `pwd`/../ndk-toolchain
./build/tools/make_standalone_toolchain.py \
	--arch arm64 --api $toolchain_api \
	--install-dir `pwd`/../ndk-toolchain-arm64
./build/tools/make_standalone_toolchain.py \
	--arch x86_64 --api $toolchain_api \
	--install-dir `pwd`/../ndk-toolchain-x64
for tc in ndk-toolchain{,-arm64,-x64}; do
	pushd ../$tc

	rm -rf bin/py* lib/{lib,}py* # remove python because it can cause breakage
	# add gas-preprocessor.pl for ffmpeg + clang on ARM
	wget "https://git.libav.org/?p=gas-preprocessor.git;a=blob_plain;f=gas-preprocessor.pl;hb=HEAD" \
		-O bin/gas-preprocessor.pl
	chmod +x bin/gas-preprocessor.pl
	# make wrapper to pass api level to gcc (due to Unified Headers)
	exe=`echo bin/*-linux-android*-gcc`
	mv $exe{,.real}
	printf '#!/bin/sh\nexec $0.real -D__ANDROID_API__=%s "$@"\n' $toolchain_api >$exe
	chmod +x $exe

	popd
done
cd ..

cd ..

mkdir -p deps && cd deps

# nettle
mkdir nettle
cd nettle
wget https://ftp.gnu.org/gnu/nettle/nettle-$v_nettle.tar.gz -O - | \
	tar -xz -f - --strip-components=1
cd ..

# gnutls
mkdir gnutls
cd gnutls
wget ftp://ftp.gnutls.org/gcrypt/gnutls/v${v_gnutls%.*}/gnutls-$v_gnutls.tar.xz -O - | \
	tar -xJ -f - --strip-components=1
cd ..

# ffmpeg
git clone https://github.com/FFmpeg/FFmpeg ffmpeg

# freetype2
git clone git://git.sv.nongnu.org/freetype/freetype2.git

# fribidi
mkdir fribidi
cd fribidi
wget http://fribidi.org/download/fribidi-$v_fribidi.tar.bz2 -O - | \
	tar -xj -f - --strip-components=1
cd ..

# libass
git clone https://github.com/libass/libass

# lua
mkdir lua
cd lua
wget http://www.lua.org/ftp/lua-$v_lua.tar.gz -O - | \
	tar -xz -f - --strip-components=1
cd ..

# mpv
git clone https://github.com/mpv-player/mpv

cd ..

# mpv-android
git clone https://github.com/mpv-android/mpv-android

# youtube-dl
wget https://kitsunemimi.pw/ytdl/dist.zip
mkdir -p mpv-android/app/src/main/assets/ytdl
unzip dist.zip -o -d mpv-android/app/src/main/assets/ytdl && rm dist.zip
