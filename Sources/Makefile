.PHONY: default build run

default: build run
build:
	if [ ! -d "../Binaries" ]; then \
  		mkdir ../Binaries; \
	fi
	fasm main.asm main.o
	gcc main.o -o ../Binaries/StorageDevicesOperations.run
	objdump -S -M intel -d ../Binaries/StorageDevicesOperations.run > obj.dump

run:
	sudo ../Binaries/StorageDevicesOperations.run
