#!/bin/bash
# 把 tar, tar.gz, tar.xz 等压缩包转换成deb以便UOS的打包系统进行签名

set -e

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
appName=`echo "$basename" | grep -P '^[a-z][a-z0-9]+(-[a-z][a-z0-9]+)*' -o`
version=`echo "$basename" | grep -P '^[a-z][a-z0-9]+(-[a-z][a-z0-9]+)*-\K([0-9.]+)' -o || echo 1.0.0`
arch="amd64"

if ! [ "$(echo "$basename" | grep -P 'i[36]86' -o)"  = "" ]; then
    arch="i386"
fi

rm -rf /tmp/tar-to-deb
mkdir -p /tmp/tar-to-deb/extract/DEBIAN/

cat <<EOF > /tmp/tar-to-deb/extract/DEBIAN/control
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
cat /tmp/tar-to-deb/extract/DEBIAN/control
echo -------------------------------------

echo -e "Extract tar to:\n\t/tmp/tar-to-deb/extract/"
tar xf "$tar" -C /tmp/tar-to-deb/extract

echo "Repacking..."
dpkg-deb -b "/tmp/tar-to-deb/extract/" "$debDir/$appName-$version-$arch.deb"

echo "Cleaning..."
echo -e "\trm -rf /tmp/tar-to-deb/"
rm -rf /tmp/tar-to-deb/

echo -n -e "Package:\n\t"
ls -lh "$debDir/$appName-$version-$arch.deb"
