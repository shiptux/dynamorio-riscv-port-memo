# 编译环境的准备

### 安装 docker
由于本配置依赖 Docker 以及 docker-compose, 请确保安装.
参考 https://mirrors.tuna.tsinghua.edu.cn/help/docker-ce/


## 太长不看版本

```
# 克隆本仓库 
git clone https://github.com/shiptux/dynamorio-riscv-port-memo.git
cd dynamorio-riscv-port-memo
# 克隆 DynamoRIO (可以是上游也可以是你的 Fork)
git clone https://github.com/DynamoRIO/dynamorio.git
# 构建编译环境
docker-compose up -d
# 连接编译环境
docker exec -it dynamorio-riscv64-compile bash
# 使用 CI 脚本测试构建 (构建产物见 build 等文件夹)
./suite/runsuite_wrapper.pl automated_ci 64_only
```


## 手动安装

### 使用 docker 准备编译环境

此处我的选型是 Ubuntu (22.04) , 基于 DynamoRIO 上游 Github action 所使用的版本和其他依赖综合考虑选择.

```bash
$ sudo docker pull ubuntu:22.04
```

拉取位于 Github 的上游源码到本地后映射到容器内部

```bash
$ git clone git@github.com:DynamoRIO/dynamorio.git
$ cd dynamorio
# 映射源码路径到容器内部
$ sudo docker run -idt -v $(pwd):/root/dynamorio --name dynamorio-compile ubuntu:22.04
$ sudo docker exec -it dynamorio-riscv64 bash
```

安装依赖以及交叉编译需求

``` bash
# 官方的依赖包 注意以下命令发生在容器中
$ apt-get install cmake g++ g++-multilib doxygen git zlib1g-dev libunwind-dev libsnappy-dev liblz4-dev3 crossbuild-essential-riscv64 python3 -y

$ cd /root/dynamorio && mkdir build && cd build
$ cmake -DCMAKE_TOOLCHAIN_FILE=../make/toolchain-riscv64.cmake ../
# Build.
$ make -j
# Run echo under DR to see if it works. If you configured for a debug or 32-bit
# build, your path will be different. For example, a 32-bit debug build would put drrun in ./bin32/ and need -debug flag to run debug build.
$ ./bin64/drrun echo hello -v 
```

通常可以在本地容器中仿照 CI 本地进行构建
CI 脚本位于 dynamorio/.github/workflows 目录下, 比如 RISC-V 的 CI 脚本为 ci-riscv64.yml
```bash
# 此处修改自 Github Action 脚本
# 也许你需要先安装 software-properties-common 软件包来提供以下命令
add-apt-repository 'deb [trusted=yes arch=riscv64] http://deb.debian.org/debian-ports sid main'

apt download libunwind8:riscv64 libunwind-dev:riscv64 liblzma5:riscv64 \
zlib1g:riscv64 zlib1g-dev:riscv64 libsnappy1v5:riscv64 libsnappy-dev:riscv64 \
liblz4-1:riscv64 liblz4-dev:riscv64

mkdir ../extract
for i in *.deb; do dpkg-deb -x $i ../extract; done
for i in include lib; do rsync -av ../extract/usr/${i}/riscv64-linux-gnu/ /usr/riscv64-linux-gnu/${i}/; done
rsync -av ../extract/usr/include/ /usr/riscv64-linux-gnu/include/
rsync -av ../extract/lib/riscv64-linux-gnu/ /usr/riscv64-linux-gnu/lib/
```
## 测试环境的准备

qemu 下方便测试的办法
常见的 qemu 映射文件中我选择了 [9p](https://wiki.qemu.org/Documentation/9psetup)
只需要在 qemu 启动脚本中加入 
需要注意的是
```bash
-fsdev local,security_model=passthrough,id=fsdev0,path=/path/dynamorio/ -device virtio-9p-device,id=fs0,fsdev=fsdev0,mount_tag=hostshare

# 然后在 qemu 中通过 
sudo mount -t 9p -o trans=virtio hostshare $HOME/dynamorio -oversion=9p2000.L
```
sudo mount -t 9p -o trans=virtio hostshare /root/dynamorio -oversion=9p2000.L

### Reference:

https://wiki.qemu.org/Documentation/9psetup
https://dynamorio.org/page_building.html
