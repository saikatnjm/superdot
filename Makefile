# SuperDot
#   make                          build ./superdot
#   sudo make install             install system-wide (default PREFIX=/usr/local)
#   make install PREFIX=/usr DESTDIR=pkg/   staged install, used by the .deb/.rpm/Arch packages
#   sudo make uninstall
#   make data                     re-download Unicode emoji + CLDR keywords and rebuild emoji-data.h
# Build needs a C compiler, pkg-config and the GTK 3 + X11 development files:
#   Debian/Ubuntu/Mint: sudo apt install build-essential pkg-config libgtk-3-dev
#   Fedora:             sudo dnf install gcc make pkgconf-pkg-config gtk3-devel libX11-devel
#   Arch/Manjaro:       sudo pacman -S --needed base-devel gtk3
#   openSUSE:           sudo zypper install gcc make pkg-config gtk3-devel libX11-devel

CC         ?= gcc
CFLAGS     ?= -Os -Wall -Wextra -Wno-unused-parameter -Wno-missing-field-initializers
PKGS        = gtk+-3.0 x11
PREFIX     ?= /usr/local
BINDIR     ?= $(PREFIX)/bin
LIBDIR     ?= $(PREFIX)/lib/superdot
DATADIR    ?= $(PREFIX)/share
SYSCONFDIR ?= /etc
UDEVDIR    ?= $(PREFIX)/lib/udev/rules.d
MODLOADDIR ?= $(PREFIX)/lib/modules-load.d
ID          = io.github.superdot.SuperDot
UNICODE     = https://unicode.org/Public/emoji/latest/emoji-test.txt
CLDR        = https://raw.githubusercontent.com/unicode-org/cldr/main/common

superdot: superdot.c emoji-data.h
	$(CC) -std=gnu11 $(CFLAGS) -DSETUP_DIR='"$(LIBDIR)"' -o $@ $< -Wl,--as-needed $(LDFLAGS) \
		$$(pkg-config --cflags --libs $(PKGS)) -ldl

data: tools/gen-data.py data/kaomoji.txt data/symbols.txt
	mkdir -p tools/cache
	curl -sSfL -o tools/cache/emoji-test.txt $(UNICODE)
	curl -sSfL -o tools/cache/en.xml $(CLDR)/annotations/en.xml
	curl -sSfL -o tools/cache/en-derived.xml $(CLDR)/annotationsDerived/en.xml
	python3 -I tools/gen-data.py tools/cache/emoji-test.txt tools/cache/en.xml tools/cache/en-derived.xml > emoji-data.h

install: superdot
	install -Dm755 superdot                      $(DESTDIR)$(BINDIR)/superdot
	install -Dm755 superdot-setup                $(DESTDIR)$(LIBDIR)/superdot-setup
	install -Dm644 data/$(ID).desktop            $(DESTDIR)$(DATADIR)/applications/$(ID).desktop
	install -Dm644 data/$(ID).svg                $(DESTDIR)$(DATADIR)/icons/hicolor/scalable/apps/$(ID).svg
	install -Dm644 data/$(ID).metainfo.xml       $(DESTDIR)$(DATADIR)/metainfo/$(ID).metainfo.xml
	install -Dm644 data/superdot-autostart.desktop $(DESTDIR)$(SYSCONFDIR)/xdg/autostart/superdot.desktop
	install -Dm644 data/70-superdot-uinput.rules $(DESTDIR)$(UDEVDIR)/70-superdot-uinput.rules
	install -Dm644 data/superdot-uinput.conf     $(DESTDIR)$(MODLOADDIR)/superdot-uinput.conf
	install -Dm644 LICENSE                       $(DESTDIR)$(DATADIR)/licenses/superdot/LICENSE
	install -Dm644 LICENSES/Unicode-3.0.txt     $(DESTDIR)$(DATADIR)/licenses/superdot/Unicode-3.0.txt

uninstall:
	rm -f $(DESTDIR)$(BINDIR)/superdot $(DESTDIR)$(LIBDIR)/superdot-setup \
	      $(DESTDIR)$(DATADIR)/applications/$(ID).desktop \
	      $(DESTDIR)$(DATADIR)/icons/hicolor/scalable/apps/$(ID).svg \
	      $(DESTDIR)$(DATADIR)/metainfo/$(ID).metainfo.xml \
	      $(DESTDIR)$(SYSCONFDIR)/xdg/autostart/superdot.desktop \
	      $(DESTDIR)$(UDEVDIR)/70-superdot-uinput.rules \
	      $(DESTDIR)$(MODLOADDIR)/superdot-uinput.conf \
	      $(DESTDIR)$(DATADIR)/licenses/superdot/LICENSE $(DESTDIR)$(DATADIR)/licenses/superdot/Unicode-3.0.txt
	-rmdir $(DESTDIR)$(LIBDIR) $(DESTDIR)$(DATADIR)/licenses/superdot 2>/dev/null

clean:
	rm -f superdot

.PHONY: data install uninstall clean
