include config.mk

.POSIX:
.SUFFIXES: .c .o

HDR = arg.h config.def.h proc.h reboot.h util.h
LIB = \
	util/agetcwd.o      \
	util/apathmax.o     \
	util/eprintf.o      \
	util/estrtol.o      \
	util/proc.o         \
	util/putword.o      \
	util/recurse.o      \
	util/strlcat.o      \
	util/strlcpy.o      \
	util/tty.o

SRC = \
	chvt.c              \
	clear.c             \
	ctrlaltdel.c        \
	df.c                \
	dmesg.c             \
	eject.c             \
	fallocate.c         \
	free.c              \
	getty.c             \
	halt.c              \
	id.c                \
	insmod.c            \
	killall5.c          \
	lsmod.c             \
	lsusb.c             \
	mknod.c             \
	mkswap.c            \
	mount.c             \
	mountpoint.c        \
	pagesize.c          \
	pidof.c             \
	pivot_root.c        \
	ps.c                \
	rmmod.c             \
	stat.c              \
	su.c                \
	swapoff.c           \
	swapon.c            \
	switch_root.c       \
	truncate.c          \
	umount.c            \
	unshare.c           \
	uptime.c            \
	watch.c             \
	who.c

MAN1 = \
	chvt.1              \
	clear.1             \
	df.1                \
	dmesg.1             \
	eject.1             \
	fallocate.1         \
	free.1              \
	id.1                \
	mknod.1             \
	mountpoint.1        \
	pagesize.1          \
	pidof.1             \
	ps.1                \
	stat.1              \
	su.1                \
	truncate.1          \
	unshare.1           \
	uptime.1            \
	watch.1             \
	who.1

MAN8 = \
	ctrlaltdel.8        \
	getty.8             \
	halt.8              \
	insmod.8            \
	killall5.8          \
	lsmod.8             \
	lsusb.8             \
	mkswap.8            \
	mount.8             \
	pivot_root.8        \
	rmmod.8             \
	swapoff.8           \
	swapon.8            \
	switch_root.8       \
	umount.8

OBJ = $(SRC:.c=.o) $(LIB)
BIN = $(SRC:.c=)

all: options binlib

options:
	@echo ubase build options:
	@echo "CFLAGS   = $(CFLAGS)"
	@echo "LDFLAGS  = $(LDFLAGS)"
	@echo "CC       = $(CC)"

binlib: util.a
	$(MAKE) bin

bin: $(BIN)

$(OBJ): config.h util.h config.mk

config.h:
	@echo creating $@ from config.def.h
	@cp config.def.h $@

.o:
	@echo LD $@
	@$(LD) -o $@ $< util.a $(LDFLAGS)

.c.o:
	@echo CC $<
	@$(CC) -c -o $@ $< $(CFLAGS)

util.a: $(LIB)
	@echo AR $@
	@$(AR) -r -c $@ $(LIB)
	@ranlib $@

install: all
	@echo installing executables to $(DESTDIR)$(PREFIX)/bin
	@mkdir -p $(DESTDIR)$(PREFIX)/bin
	@cp -f $(BIN) $(DESTDIR)$(PREFIX)/bin
	@cd $(DESTDIR)$(PREFIX)/bin && chmod 755 $(BIN)
	@echo installing manual pages to $(DESTDIR)$(MANPREFIX)/man1
	@mkdir -p $(DESTDIR)$(MANPREFIX)/man1
	@for m in $(MAN1); do sed "s/VERSION/$(VERSION)/g" < "$$m" > $(DESTDIR)$(MANPREFIX)/man1/"$$m"; done
	@echo installing manual pages to $(DESTDIR)$(MANPREFIX)/man8
	@mkdir -p $(DESTDIR)$(MANPREFIX)/man8
	@for m in $(MAN8); do sed "s/VERSION/$(VERSION)/g" < "$$m" > $(DESTDIR)$(MANPREFIX)/man8/"$$m"; done
	@chmod 644 $(DESTDIR)$(MANPREFIX)/man1/$(MAN1)
	@chmod 644 $(DESTDIR)$(MANPREFIX)/man8/$(MAN8)

uninstall:
	@echo removing executables from $(DESTDIR)$(PREFIX)/bin
	@cd $(DESTDIR)$(PREFIX)/bin && rm -f $(BIN)
	@echo removing manual pages from $(DESTDIR)$(MANPREFIX)/man1
	@cd $(DESTDIR)$(MANPREFIX)/man1 && rm -f $(MAN)

dist: clean
	@echo creating dist tarball
	@mkdir -p ubase-$(VERSION)
	@cp -r LICENSE Makefile config.mk TODO $(SRC) $(MAN) util $(HDR) ubase-$(VERSION)
	@tar -cf ubase-$(VERSION).tar ubase-$(VERSION)
	@gzip ubase-$(VERSION).tar
	@rm -rf ubase-$(VERSION)

ubase-box: config.h $(SRC) util.a
	@echo creating box binary
	@mkdir -p build
	@cp $(HDR) build
	@cp config.h build
	@for f in $(SRC); do sed "s/^main(/`basename $$f .c`_&/" < $$f > build/$$f; done
	@echo '#include <libgen.h>'  > build/$@.c
	@echo '#include <stdio.h>'  >> build/$@.c
	@echo '#include <stdlib.h>' >> build/$@.c
	@echo '#include <string.h>' >> build/$@.c
	@echo '#include "util.h"'   >> build/$@.c
	@for f in $(SRC); do echo "int `basename $$f .c`_main(int, char **);" >> build/$@.c; done
	@echo 'int main(int argc, char *argv[]) { char *s = basename(argv[0]); if(!strcmp(s,"ubase-box")) { argc--; argv++; s = basename(argv[0]); } if(0) ;' >> build/$@.c
	@for f in $(SRC); do echo "else if(!strcmp(s, \"`basename $$f .c`\")) `basename $$f .c`_main(argc, argv);" >> build/$@.c; done
	@echo 'else {' >> build/$@.c
	@for f in $(SRC); do echo "printf(\"`basename $$f .c`\"); putchar(' ');" >> build/$@.c; done
	@echo "putchar(0xa); }; return EXIT_SUCCESS; }" >> build/$@.c
	@echo LD $@
	@$(LD) -o $@ build/*.c util.a $(CFLAGS) $(LDFLAGS)
	@rm -r build

clean:
	@echo cleaning
	@rm -f $(BIN) $(OBJ) $(LIB) util.a ubase-box
