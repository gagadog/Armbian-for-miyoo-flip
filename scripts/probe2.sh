#!/bin/bash
probe() {
    echo "== $1"
    curl -sIL --max-time 25 "$1" | grep -iE '^(HTTP/|location:|content-length:|content-type:)' | head -8
    echo
}
probe "https://dl.armbian.com/"
probe "https://dl.armbian.com/orangepi3b/"
probe "https://mirrors.tuna.tsinghua.edu.cn/armbian-images/"
probe "https://mirror.nju.edu.cn/armbian-images/"
probe "https://mirrors.ustc.edu.cn/armbian-images/"
probe "https://mirrors.bfsu.edu.cn/armbian-images/"
