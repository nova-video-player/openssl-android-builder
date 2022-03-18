#!/bin/bash

while getopts "a:" opt; do
  case $opt in
    a)
  ARCH=$OPTARG ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
  esac
done

if [[ -z "${ARCH}" ]] ; then
  echo 'You need to input arch with -a ARCH.'
  echo 'Supported archs are:'
  echo -e '\tarm arm64 mips mips64 x86 x86_64'
  exit 1
fi

source setup.sh

LOCAL_PATH=$($READLINK -f .)

if [ ! -d openssl.git ]; then
  git clone https://github.com/openssl/openssl openssl.git --bare --depth=1 -b OpenSSL_1_1_1m
#  git clone https://github.com/openssl/openssl openssl.git --depth=1 -b openssl-3.0.1
fi

OPENSSL_BARE_PATH=$($READLINK -f openssl.git)
ANDROID_API=21

ARCH_CONFIG_OPT=

case "${ARCH}" in
  'arm')
    ARCH_TRIPLET='arm-linux-androideabi'
    CLANG_TRIPLET='armv7a-linux-androideabi'
    ABI='armeabi-v7a' ;;
  'arm64')
    ARCH_TRIPLET='aarch64-linux-android'
    CLANG_TRIPLET=${ARCH_TRIPLET}
    ABI='arm64-v8a' ;;
  'x86')
    ARCH_TRIPLET='i686-linux-android'
    CLANG_TRIPLET=${ARCH_TRIPLET}
    ARCH_CONFIG_OPT='--disable-asm'
    ABI='x86' ;;
  'x86_64')
    ARCH_TRIPLET='x86_64-linux-android'
    CLANG_TRIPLET=${ARCH_TRIPLET}
    ABI='x86_64' ;;
  *)
    echo "Arch ${ARCH} is not supported."
    exit 1 ;;
esac

OPENSSL_DIR="$(mktemp -d)"
#OPENSSL_DIR="$PWD/openssl-$ABI"
mkdir -p ${OPENSSL_DIR}
git clone "${OPENSSL_BARE_PATH}" "${OPENSSL_DIR}"

pushd "${OPENSSL_DIR}"

git clean -fdx

OS=$(uname -s | tr '[:upper:]' '[:lower:]')
CROSS_DIR=$NDK_PATH/toolchains/llvm/prebuilt/${OS}-x86_64
CROSS_PREFIX="${CROSS_DIR}/bin/${ARCH_TRIPLET}"

export PATH=${CROSS_DIR}/bin:$PATH

export AR=${CROSS_DIR}/bin/llvm-ar
export CC=${CROSS_DIR}/bin/${CLANG_TRIPLET}${ANDROID_API}-clang
export AS=$CC
export CXX=${CROSS_DIR}/bin/${CLANG_TRIPLET}${ANDROID_API}-clang++
export LD=${CROSS_DIR}/bin/ld
export RANLIB=${CROSS_DIR}/bin/llvm-ranlib
export STRIP=${CROSS_DIR}/bin/llvm-strip
export NM=${CROSS_DIR}/bin/llvm-nm
export AR=${CROSS_DIR}/bin/llvm-ar

export CFLAGS="-Os"
export LDFLAGS="-Wl,-Bsymbolic"

mkdir -p "${OPENSSL_DIR}/dist-${ABI}"

export PKG_CONFIG_LIBDIR=${LOCAL_PATH}

./Configure android-${ARCH} no-shared \
  -D__ANDROID_API__=${ANDROID_API} \
  --prefix=${LOCAL_PATH}/dist-${ABI}
make -j${CORES}
make install_sw
make clean

mkdir -p ${LOCAL_PATH}/dist-${ABI}

popd

cp -R "${OPENSSL_DIR}/build/${ABI}/"  "${LOCAL_PATH}/dist-${ABI}/"
rm -Rf "${OPENSSL_DIR}"
