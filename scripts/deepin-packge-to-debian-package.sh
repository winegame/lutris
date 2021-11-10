#!/bin/bash
# 把deepin deb包重打包为debian deb包，以解决在debian/ubuntu等非deepin/uos发行版中安装后没有图标的问题

set -e

deb="$1"
debDir="$2"

if [ "$deb" = "" ] || [ "$debDir" = "" ] || ! [ "$UID" = "0" ]; then
    echo -e "Usage:\n\tsudo $0 <path-of-deb> <dir-to-save-converted-deb>"
    echo -e "Example:\n\tsudo $0 /home/hu60/net.winegame.client_0.5.7.1_amd64.deb /home/hu60/debian"
    exit
fi

rm -rf /tmp/deepin-packge-to-debian-package
mkdir -p /tmp/deepin-packge-to-debian-package/extract/DEBIAN

echo -e "Extract deb to:\n\t/tmp/deepin-packge-to-debian-package/extract/"
dpkg -X "$deb" /tmp/deepin-packge-to-debian-package/extract >/dev/null
dpkg -e "$deb" /tmp/deepin-packge-to-debian-package/extract/DEBIAN

packageName="$(ls /tmp/deepin-packge-to-debian-package/extract/opt/apps/)"
echo -e "Package name:\n\t$packageName"

linkDir() {
    find "/tmp/deepin-packge-to-debian-package/extract$1/" -type f | \
    sed 's#^/tmp/deepin-packge-to-debian-package/extract##' | \
    while read src; do
        dst="$(echo "$src" | sed "s#^$1/#$2/#")"
        echo -e "\t$src -> $dst"
        mkdir -p "/tmp/deepin-packge-to-debian-package/extract$(dirname "$dst")"
        ln -s "$src" "/tmp/deepin-packge-to-debian-package/extract$dst"
    done
}

echo "Link entries:"
ls "/tmp/deepin-packge-to-debian-package/extract/opt/apps/$packageName/entries/" | while read dir; do
    linkDir "/opt/apps/$packageName/entries/$dir" "/usr/share/$dir"
done

echo "Cleaning depends..."
sed -i 's/deepin-elf-verify[^,]*,\s*//' /tmp/deepin-packge-to-debian-package/extract/DEBIAN/control
sed -i '/^Depends: deepin-elf-verify[^,]*$/d' /tmp/deepin-packge-to-debian-package/extract/DEBIAN/control

echo "Repacking..."
baseName="$(basename "$deb")"
dpkg-deb -b "/tmp/deepin-packge-to-debian-package/extract" "$debDir/$baseName"

echo "Cleaning..."
echo -e "\trm -rf /tmp/deepin-packge-to-debian-package/"
rm -rf /tmp/deepin-packge-to-debian-package/

echo -n -e "Package:\n\t"
ls -lh "$debDir/$baseName"
