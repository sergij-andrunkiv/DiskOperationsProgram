.PHONY: default build run

default: build run
build:
	rm -r ../Binaries
	mkdir ../Binaries
	fasm main.asm main.o
	gcc main.o -o ../Binaries/StorageDevicesOperations.run
	objdump -S -M intel -d ../Binaries/StorageDevicesOperations.run > obj.dump

run:
	sudo ../Binaries/StorageDevicesOperations.run