# libkestrel-hint. Plain C, no dependencies. `make`, then `make install`.
#
# The package build (section 8) uses this Makefile; nothing here runs on the
# dev host.

CC ?= cc
AR ?= ar
CFLAGS ?= -O2 -Wall -Wextra -fPIC
PREFIX ?= /usr
DESTDIR ?=

all: libkestrel-hint.a libkestrel-hint.so kestrel-hint

libkestrel-hint.a: kestrel_hint.o
	$(AR) rcs $@ $^

libkestrel-hint.so: kestrel_hint.o
	$(CC) -shared -o $@ $^

kestrel-hint: kestrel-hint.o kestrel_hint.o
	$(CC) $(CFLAGS) -o $@ $^

%.o: %.c kestrel_hint.h
	$(CC) $(CFLAGS) -c $< -o $@

install: all
	install -Dm644 kestrel_hint.h "$(DESTDIR)$(PREFIX)/include/kestrel_hint.h"
	install -Dm644 libkestrel-hint.a "$(DESTDIR)$(PREFIX)/lib/libkestrel-hint.a"
	install -Dm755 libkestrel-hint.so "$(DESTDIR)$(PREFIX)/lib/libkestrel-hint.so"
	install -Dm755 kestrel-hint "$(DESTDIR)$(PREFIX)/bin/kestrel-hint"

clean:
	rm -f *.o *.a *.so kestrel-hint

.PHONY: all install clean
