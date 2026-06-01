#!/bin/bash

echo "Bat dau bien dich ASM -> HEX..."

# 1. Dịch ra ELF
riscv64-unknown-elf-gcc -march=rv32i -mabi=ilp32 -nostdlib -Ttext 0x00000000 ../01_tb/aoi.S -o aoi.elf
if [ $? -ne 0 ]; then
    echo "Loi bien dich ASM!"
    exit 1
fi

# 2. Xuất ra HEX (width=4)
riscv64-unknown-elf-objcopy -O verilog --verilog-data-width=4 aoi.elf init_imem.hex
if [ $? -ne 0 ]; then
    echo "Loi tao file HEX!"
    exit 1
fi

echo "Thanh cong! Da tao ra file init_imem.hex"