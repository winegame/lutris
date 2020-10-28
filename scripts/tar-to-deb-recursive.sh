#!/bin/bash
# 把当前目录中的 tar, tar.gz, tar.xz 等压缩包转换成deb以便UOS的打包系统进行签名
# 转换后的deb保存在 ../deb/ 文件夹中

if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
	echo -e "Usage:\n\tcd <tar-file-dir>\n\t$(realpath "$0") [jobs]\n\tfind ../deb -name '*.deb'"
	echo -e "Example:\n\tcd /home/hu60/tar\n\t$(realpath "$0") 8\n\tfind ../deb -name '*.deb'"
    exit
fi

if ! [ "$UID" = "0" ]; then
    exec sudo "$0" "$@"
fi

JOBS=1
TAR2DEB="$(dirname "$0")/tar-to-deb.sh"

trap "JOBS=0; exit" HUP INT PIPE QUIT TERM

if ! [ "$1" = "" ]; then
    JOBS="$1"
fi

find . -type f | while read f; do
    if [ "$JOBS" = "0" ]; then
        exit
    fi

    while [ "$(ps ax | grep "/bin/bash $TAR2DEB" | grep -v grep | wc -l)" -ge "$JOBS" ]; do
        sleep 1
    done

    dirname="../deb/$(dirname "$f")"
    mkdir -p "$dirname"
    execJobs="$(ps ax | grep "/bin/bash $TAR2DEB" | grep -v grep | wc -l)"
    echo "[jobs: $execJobs/$JOBS] sudo $TAR2DEB" "$f" "$dirname"
    "$TAR2DEB" "$f" "$dirname" &
done

