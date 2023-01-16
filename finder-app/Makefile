CC=gcc
OP=-w
str=aarch64-none-linux-gnu-

ifeq ($(CROSS_COMPILE),$(str))
CC=aarch64-linux-gnu-gcc
$(shell aarch64-linux-gnu-gcc -print-sysroot -v > ../assignments/assignment2/cross-compile.txt)
endif

default:writer.c
	$(CC)  $(OP) $< -o writer 


clean:writer
	rm $<
