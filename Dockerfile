FROM ubuntu:22.04

RUN set -e \
    && apt update \
    && apt-get install -y software-properties-common rsync cmake g++ g++-multilib doxygen git zlib1g-dev libunwind-dev libsnappy-dev liblz4-dev python3 \
    && apt install crossbuild-essential-riscv64 -y \
    && add-apt-repository 'deb [trusted=yes arch=riscv64] http://deb.debian.org/debian-ports sid main' \
    && apt download libunwind8:riscv64 libunwind-dev:riscv64 liblzma5:riscv64 zlib1g:riscv64 zlib1g-dev:riscv64 libsnappy1v5:riscv64 libsnappy-dev:riscv64 liblz4-1:riscv64 liblz4-dev:riscv64 \
    && mkdir extract \
    && for i in *.deb; do dpkg-deb -x $i extract; done \
    && for i in include lib; do rsync -av extract/usr/${i}/riscv64-linux-gnu/ /usr/riscv64-linux-gnu/${i}/; done \
    && rsync -av extract/usr/include/ /usr/riscv64-linux-gnu/include/ \
    && rsync -av extract/lib/riscv64-linux-gnu/ /usr/riscv64-linux-gnu/lib/ \
    && rm -rvf *.deb extract \
    && apt clean

VOLUME /dynamorio

WORKDIR /dynamorio
