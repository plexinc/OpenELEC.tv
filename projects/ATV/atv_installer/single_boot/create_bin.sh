#!/bin/bash

SCRIPT_DIR=$(dirname $0)
TARGET_ARCHIVE=$1

if [ -f "${TARGET_ARCHIVE}" ];then
    :
else
    echo "invalid archive file"
    exit 1
fi

if [ -f "installer.bin" ];then
    echo "removing old installer.bin"
    rm installer.bin
fi

TARGET_TMP=$(mktemp -d /tmp/selfextract.XXXXXX)
INSTALLER_TMP=$(mktemp -d /tmp/selfextract.XXXXXX)
PAYLOAD_TMP=$(mktemp -d /tmp/selfextract.XXXXXX)
BIN_TMP=$(mktemp /tmp/selfextract.XXXXXX)

#echo $TARGET_TMP
#echo $INSTALLER_TMP
#echo $PAYLOAD_TMP

echo "copying installer files"
cp -a "${SCRIPT_DIR}"/* "${INSTALLER_TMP}"

echo "extracting target image"
tar -jxf "${TARGET_ARCHIVE}" -C "${TARGET_TMP}"

echo "copying target into place"
cp -a "${TARGET_TMP}"/*/target/* "${INSTALLER_TMP}/target/"

# remove normal kernel image
rm -rf "${INSTALLER_TMP}"/target/KERNEL*

echo "creating installer tarball"
# create installer tarball
cd "${INSTALLER_TMP}"
tar -czf "${PAYLOAD_TMP}"/installer.tar.gz *
cd - &>/dev/null

echo "creating bin file"
cat decompress.sh "${PAYLOAD_TMP}"/installer.tar.gz > ${BIN_TMP}
mv "${BIN_TMP}" installer.bin
chmod +x installer.bin

echo "installer.bin successfully created"
