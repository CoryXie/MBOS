# MBOS64 top level make file
MBOS = $(shell pwd)
DATE=$(shell date +%F-%H-%M-%S)
CC = gcc 
G++ = g++
LD  = ld
RM = rm -f

INCLUDEDIR = -Iinclude

CFLAGS = -ffreestanding -nostdlib -nostdinc -O0 -g -DKERNEL -Wl,--build-id=none
CFLAGS += -Wall -fomit-frame-pointer -std=c99 -std=gnu99 -O $(INCLUDEDIR)

CPPFLAGS = -Wall -fomit-frame-pointer -O $(INCLUDEDIR)

LDFLAGS = -nostdlib -nostdinc -nodefaultlibs -Bstatic -Tmbos.ld 


OBJS =  boot/boot.o \
	main/kernel.o


DEPS = $(OBJS:.o=.dep)

-include $(OBJS:.o=.dep)

# The kernel filename
KERNELFN = mbos

# Link the kernel statically with fixed text+data address @1M
$(KERNELFN) : $(OBJS)
	$(LD) $(LDFLAGS) -o $@ $(OBJS) -b binary

# Compile the source files

%.o : %.c
	$(COMPILE.c) -MD -o $@ $<
	@cp $*.d $*.dep; \
	sed -e 's/#.*//' -e 's/^[^:]*: *//' -e 's/ *\\$$//' \
		-e '/^$$/ d' -e 's/$$/ :/' < $*.d >> $*.dep; \
	rm -f $*.d	
	
%.o : %.S
	$(COMPILE.S) -MD -D__ASM__ -c -o $@ $<
	@cp $*.d $*.dep; \
	sed -e 's/#.*//' -e 's/^[^:]*: *//' -e 's/ *\\$$//' \
		-e '/^$$/ d' -e 's/$$/ :/' < $*.d >> $*.dep; \
	rm -f $*.d	
		
# Clean up the junk
clean:
	$(RM) $(OBJS) $(KERNELFN) $(OBJS) $(DEPS)


cdrom.iso: dist/boot/grub/stage2_eltorito dist/boot/grub/menu.lst $(KERNELFN)
	echo $(OBJS)
	cp $(KERNELFN) 	dist/
	mkisofs -J -r -b boot/grub/stage2_eltorito \
	-no-emul-boot -boot-load-size 4 -boot-info-table \
	-o $@ dist/

sim:
	qemu-system-x86 -cdrom cdrom.iso -smp 1 -S -s &

asm:
	objdump -D -S $(KERNELFN) > $(KERNELFN).asm

sym:
	nm -A -l -n  $(KERNELFN) > $(KERNELFN).txt

