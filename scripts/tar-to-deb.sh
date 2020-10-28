#!/bin/bash
# 把 tar, tar.gz, tar.xz 等压缩包转换成deb以便UOS的打包系统进行签名

set -e

TMP_DIR="/tmp/tar-to-deb/$$"

tar="$1"
debDir="$2"
BASE_PACKAGE_NAME="net.winegame.tar"
MAINTAINER="老虎会游泳 <admin@winegame.net>"
HOMEPAGE="https://winegame.net"

if [ "$tar" = "" ] || [ "$debDir" = "" ] || ! [ "$UID" = "0" ]; then
    echo -e "Usage:\n\tsudo $0 <path-of-tar> <dir-to-save-deb>"
    echo -e "Example:\n\tsudo $0 /home/hu60/winehq-staging-5.20-x86_64.tar.xz /home/hu60/deb"
    exit
fi

typeset -l basename
basename=`basename "$tar"`

arch="amd64"
if ! [ "$(echo "$basename" | grep -P 'i[36]86' -o)"  = "" ]; then
    arch="i386"
fi

basename=`echo "$basename" | sed 's/-x86_64//g' | sed 's/-i[36]86//g' | sed 's/.tar.[xg]z//g'`
appName=`echo "$basename" | grep -P '^[a-z][a-z0-9]+(-[a-z][a-z0-9]+)*' -o`
version=`echo "$basename" | grep -P '^[a-z][a-z0-9]+(-[a-z][a-z0-9]+)*-\K([0-9.]+)' -o || echo 1.0.0`

rm -rf "$TMP_DIR"
mkdir -p "$TMP_DIR/extract/DEBIAN/"

cat <<EOF > "$TMP_DIR/extract/DEBIAN/control"
Package: $BASE_PACKAGE_NAME.$appName
Version: $version
Architecture: $arch
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
dpkg-deb -b "$TMP_DIR/extract/" "$debDir/$appName-$version-$arch.deb"

echo "Cleaning..."
echo -e "\trm -rf $TMP_DIR/"
rm -rf "$TMP_DIR/"

echo -n -e "Package:\n\t"
ls -lh "$debDir/$appName-$version-$arch.deb"
