# SSH — Sovereignity Shell
#   make test                 run unit tests, lint and load test
#   make install              install to $(DESTDIR)$(PREFIX)
#   make uninstall
PREFIX  ?= /usr
DESTDIR ?=
SHARE    = $(DESTDIR)$(PREFIX)/share/ssh-shell
BIN      = $(DESTDIR)$(PREFIX)/bin
DOC      = $(DESTDIR)$(PREFIX)/share/doc/ssh-shell
LIC      = $(DESTDIR)$(PREFIX)/share/licenses/ssh-shell
ICONS    = $(DESTDIR)$(PREFIX)/share/icons/hicolor

.PHONY: all test install uninstall
all:
	@echo "Nothing to build: SSH is interpreted QML. Try 'make test' or 'make install'."

test:
	./scripts/test.sh

install:
	install -d $(SHARE) $(BIN) $(DOC) $(LIC) $(ICONS)/scalable/apps $(ICONS)/256x256/apps
	cd src && find . -type f \( -name '*.qml' -o -name '*.js' -o -name '*.json' \) ! -name 'dev-*' \
		-exec install -Dm644 {} $(SHARE)/{} \;
	sed 's|^here=.*|here=$(PREFIX)/bin|' bin/ssh-shell > $(BIN)/ssh-shell && chmod 755 $(BIN)/ssh-shell
	install -m644 README.md CHANGELOG.md $(DOC)/
	cp -r docs $(DOC)/
	install -m644 LICENSE $(LIC)/LICENSE
	install -m644 assets/brand/ssh-icon.svg $(ICONS)/scalable/apps/ssh-shell.svg
	install -m644 assets/brand/ssh-icon-256.png $(ICONS)/256x256/apps/ssh-shell.png

uninstall:
	rm -rf $(SHARE) $(DOC) $(LIC)
	rm -f $(BIN)/ssh-shell $(ICONS)/scalable/apps/ssh-shell.svg $(ICONS)/256x256/apps/ssh-shell.png
