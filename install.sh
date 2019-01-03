#!/usr/bin/env bash


apt update
apt install -y tar build-essential \
    curl libssl-dev liblzo2-dev \
    libpam0g-dev lzop liblzo2-dev \
    libpam-dev liblz4-dev automake \
    libtool cmake


WORKDIR=
OPENSSL_FIPS_VERSION=2.0.16
OPENSSL_VERSION=1.0.2p
OPENVPN_VERSION=2.4.4
OPENSSL_DIR=${WORKDIR}/usr/local/ssl
OPENSSL_FIPS_DIR=${WORKDIR}/usr/local/ssl/fips-2.0
PATH=${OPENSSL_DIR}/bin:${PATH}
CFLAGS=-I${OPENSSL_DIR}/include
LDFLAGS=-L${OPENSSL_DIR}/lib
LD_LIBRARY_PATH=${OPENSSL_DIR}/lib
PKG_CONFIG_PATH=${OPENSSL_DIR}/lib/pkgconfig

curl -sL -O https://www.openssl.org/source/openssl-fips-${OPENSSL_FIPS_VERSION}.tar.gz
tar xzf openssl-fips-${OPENSSL_FIPS_VERSION}.tar.gz

export FIPSDIR=${OPENSSL_FIPS_DIR}

pushd openssl-fips-${OPENSSL_FIPS_VERSION}
./config
make -s && make install
popd

curl -sL -O https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz
tar xzf openssl-${OPENSSL_VERSION}.tar.gz

pushd openssl-${OPENSSL_VERSION}
./config \
shared \
fips \
--with-fipsdir=${OPENSSL_FIPS_DIR} \
--openssldir=${OPENSSL_DIR}
make -s
make install
popd

ln -s /usr/local/ssl/bin/openssl /usr/local/bin/openssl
ln -s /usr/local/ssl/bin/c_rehash /usr/local/bin/c_rehash
hash -r

echo "${OPENSSL_DIR}/lib" > /etc/ld.so.conf.d/openssl-1.0.2p.conf
ldconfig -v

curl -sL -O https://swupdate.openvpn.org/community/releases/openvpn-${OPENVPN_VERSION}.tar.xz
tar xf openvpn-${OPENVPN_VERSION}.tar.xz
cp ./openvpn-fips.patch openvpn-${OPENVPN_VERSION}/openvpn-fips.patch

pushd openvpn-${OPENVPN_VERSION}

patch -Np1 --ignore-whitespace < ./openvpn-fips.patch
autoreconf -f -i
./configure --enable-fips-mode OPENSSL_CFLAGS="-I${OPENSSL_DIR}/include" OPENSSL_LIBS="-ldl -L${OPENSSL_DIR}/lib -lssl -lcrypto"
make -s
make install
popd
