#!/bin/sh
#
# Copyright 2019 ss All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at:
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# -----------------------------------------
# vxafl run script
# --------------------------------------
#
# Written by ss <2chashao@gmail.com>
#
stty intr ^]
echo "[*] ctrl+c remapped to ctrl+] for host"

AFL_TIMEOUT=1000+ # afl超时时间，因为需要运行到测试函数位置，所以需要将其改大一些
QEMU_VERSION="2.10.0"
CPU_TARGET="i386"
VXWORKS_VERSION="6.8"
IMAGE_PATH="$HOME/work/vxworks$VXWORKS_VERSION/MS-DOS.vmdk"
VXWORKS_PATH="$HOME/work/vxworks$VXWORKS_VERSION/vxWorks"
# FUZZ_IN="./RPCBIND/input"
# FUZZ_OUT="./RPCBIND/output"
FUZZ_IN="./example/fuzzin"
FUZZ_OUT="./example/fuzzout"
CPU_CORE_NUMS=`cat /proc/cpuinfo| grep processor | wc -l`
QEMU_EXEC="qemu-$QEMU_VERSION/$CPU_TARGET-softmmu/qemu-system-i386"
echo "++++++++++++++++++++++++++++++++++++++++++++++++"
echo "+   AFL base vxworks image fuzzer run script   +"
echo "++++++++++++++++++++++++++++++++++++++++++++++++"

if [ "$1" = "image" ]
then
    echo "[*] Run image"
    # $QEMU_EXEC -hda $IMAGE_PATH -s -net tap,ifname=tap0 -net nic,model=pcnet \
    $QEMU_EXEC -hda $IMAGE_PATH -s \
    -vxafl-img /home/ss/work/vxworks6.8/vxWorks \
    -vxafl-entry CrashFunc
#    -nographic \
    # -monitor stdio \
    # -d out_asm,in_asm,op,op_opt
    echo "[+] Run complete"
elif [ "$1" = "afl" ]
then
    export AFL_DEBUG_CHILD_OUTPUT=1 # 子进程打印
    export AFL_FAST_CAL=1 
    export AFL_SKIP_CPUFREQ=1 # 避免开启performance
    set -e
    mkdir -p $FUZZ_IN $FUZZ_OUT
    echo "[*] Build Qemu"
    cd qemu-$QEMU_VERSION
    make -j $CPU_CORE_NUMS
    echo "[+] Build complete"
    cd ..
    echo "[*] Build AFL"
    make -j $CPU_CORE_NUMS
    echo "[+] Build complete"
    echo "[*] Run vxAFL"
    ./afl-fuzz -t $AFL_TIMEOUT -Q -i $FUZZ_IN -o $FUZZ_OUT  @@ $PWD/venv/bin/python vxafl.py
else
    echo "[*] Help - './run.sh image' to run image"
    echo "           './run.sh afl'   to run qemu and afl together "
fi 