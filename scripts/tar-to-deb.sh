#!/bin/bash
# 把 tar, tar.gz, tar.xz 等压缩包转换成deb以便UOS的打包系统进行签名

set -e

TMP_DIR="/tmp/tar-to-deb/$$"

tar="$1"
debDir="$2"
BASE_PACKAGE_NAME="net.winegame.tar"
MAINTAINER="老虎会游泳 <admin@winegame.net>"
HOMEPAGE="https://winegame.net"
VERSION="1.0.0"
ARCH="amd64"

if [ "$tar" = "" ] || [ "$debDir" = "" ] || ! [ "$UID" = "0" ]; then
    echo -e "Usage:\n\tsudo $0 <path-of-tar> <dir-to-save-deb>"
    echo -e "Example:\n\tsudo $0 /home/hu60/winehq-staging-5.20-x86_64.tar.xz /home/hu60/deb"
    exit
fi

typeset -l basename
basename=`basename "$tar" | sed 's/.tar.[xg]z$//g'`
appName=`echo "$basename" | sed 's/-x86_64//g' | sed 's/-i[3456]86//g'`

rm -rf "$TMP_DIR"
mkdir -p "$TMP_DIR/extract/DEBIAN/"

cat <<EOF > "$TMP_DIR/extract/DEBIAN/control"
Package: $BASE_PACKAGE_NAME.$appName
Version: $VERSION
Architecture: $ARCH
Maintainer: $MAINTAINER
Depends: tar
Homepage: $HOMEPAGE
Description: $basename
 从压缩包 '$basename' 转换而来。
EOF

echo -------------------------------------
cat "$TMP_DIR/extract/DEBIAN/control"
echo -------------------------------------

echo -e "Extract tar to:\n\t$TMP_DIR/extract/"
tar xf "$tar" -C "$TMP_DIR/extract"

echo "Repacking..."
dpkg-deb -b "$TMP_DIR/extract/" "$debDir/$basename.deb"

echo "Cleaning..."
echo -e "\trm -rf $TMP_DIR/"
rm -rf "$TMP_DIR/"

echo -n -e "Package:\n\t"
ls -lh "$debDir/$basename.deb"
