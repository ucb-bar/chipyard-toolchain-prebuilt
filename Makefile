SHELL := /bin/sh

basedir := $(dir $(realpath $(lastword $(MAKEFILE_LIST))))
basedir := $(basedir:/=)

SRCDIR ?= $(basedir)/../riscv-gnu-toolchain
WRKDIR := $(basedir)/build
STAGEDIR := $(basedir)/staging
DISTDIR := $(basedir)/dist

ifneq ($(MAKECMDGOALS),install)
hash := $(shell cd $(SRCDIR) && test -d riscv-gcc && git rev-parse HEAD)
ifeq ($(hash),)
$(error Set SRCDIR to path of riscv-gnu-toolchain working tree)
endif
endif

stamp_hash := $(basedir)/HASH
stamp_newlib := $(WRKDIR)/stamps/build-gcc-newlib-stage2
stamp_linux := $(WRKDIR)/stamps/build-gcc-linux-stage2
distname := $(DISTDIR)/pkg.tar.

scanelf := $(basedir)/pax-utils/scanelf

.PHONY: dist
dist: $(stamp_hash)

$(WRKDIR)/Makefile: $(SRCDIR)/configure
	mkdir -p $(WRKDIR)
	cd $(WRKDIR) && $(realpath $<) --prefix=$(STAGEDIR)

$(stamp_newlib): $(WRKDIR)/Makefile
	$(MAKE) -C $(WRKDIR) newlib

$(stamp_linux): $(WRKDIR)/Makefile
	$(MAKE) -C $(WRKDIR) linux

$(scanelf):
	git submodule update --init $(dir $@)
	$(MAKE) -C $(dir $@) scanelf

# Check for DT_RPATH/DT_RUNPATH entries that appear to be non-portable
# absolute paths.
# Strip debugging symbols from native ELF binaries.
$(stamp_hash): $(stamp_newlib) $(stamp_linux) $(scanelf)
	set -e && $(scanelf) -F '%a|%r|%F' -B -R $(STAGEDIR) | \
	while IFS='|' read -r arch rpath file ; do \
		test "$${arch}" != UNKNOWN_TYPE || continue ; \
		( IFS=: ; for f in $${rpath} ; do test "$${f}" = "$${f#/}" ; done ; ) || \
		echo "WARNING: non-portable RPATH in \"$${file}\": $${rpath}" ; \
		strip -g "$${file}" ; \
	done
	rm -rf $(DISTDIR)
	mkdir -p $(DISTDIR)
	tar -cv -f - -C $(STAGEDIR) . | split -b 48m - $(distname)
	echo '$(hash)' > $@

.PHONY: configure build-newlib build-linux scanelf
configure: $(WRKDIR)/Makefile
build-newlib: $(stamp_newlib)
build-linux: $(stamp_linux)
strip: $(stamp_strip)
scanelf: $(scanelf)

.PHONY: install
install:
	$(if $(DESTDIR),, $(error Set DESTDIR to installation path))
	mkdir -p $(DESTDIR)
	cat $(distname)* | tar -xvp -f - -C $(DESTDIR)

.PHONY: clean
clean:
	rm -rf -- $(WRKDIR) $(STAGEDIR)
	$(MAKE) -C $(dir $(scanelf)) clean

# Disable built-in suffix rules
.SUFFIXES:
