#!/bin/bash

nasm boot.asm -f bin -o boot.bin
if [ $? -eq 0 ]; then
	echo "Boot loader assembled!"
fi

nasm fs.asm -f bin -o fs.bin
if [ $? -eq 0 ]; then
	echo "Apollo assembled!"
fi

if [ -f kernel.asm ]; then
	nasm kernel.asm -f bin -o kernel.bin
	if [ $? -eq 0 ]; then
		echo "Zeus assembled!"
	fi
fi

if [ -e boot.bin ] && [ -e fs.bin ]; then
	if [ -e kernel.bin ]; then
		cat boot.bin fs.bin kernel.bin > olympus.img
	else
		cat boot.bin fs.bin > olympus.img
	fi
	echo "Assembly successful!"
else
	echo "Assembly failed!"
fi
