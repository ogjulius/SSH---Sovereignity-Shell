# SSH — Sovereignity Shell
#   make test                 run unit tests, lint and load test
#   make install              install to $(DESTDIR)$(PREFIX)
#   make uninstall
# Most people want ./install.sh instead, which builds a native package.
PREFIX  ?= /usr
DESTDIR ?=
# Absolute directory the login sessions call ssh-session from at runtime
# (Nix sets this to its store path).
RUNTIME_BINDIR ?= $(PREFIX)/bin
SHARE    = $(DESTDIR)$(PREFIX)/share/ssh-shell
BIN      = $(DESTDIR)$(PREFIX)/bin
DOC      = $(DESTDIR)$(PREFIX)/share/doc/ssh-shell
LIC      = $(DESTDIR)$(PREFIX)/share/licenses/ssh-shell
ICONS    = $(DESTDIR)$(PREFIX)/share/icons/hicolor
SESSIONS = $(DESTDIR)$(PREFIX)/share/wayland-sessions
BASHC    = $(DESTDIR)$(PREFIX)/share/bash-completion/completions
FISHC    = $(DESTDIR)$(PREFIX)/share/fish/vendor_completions.d
ZSHC     = $(DESTDIR)$(PREFIX)/share/zsh/site-functions

.PHONY: all test install uninstall
all:
	@echo "Nothing to build: SSH is interpreted QML. Try 'make test', 'make install' or ./install.sh."

test:
	./scripts/test.sh

install:
	install -d $(SHARE) $(BIN) $(DOC) $(LIC) $(ICONS)/scalable/apps $(ICONS)/256x256/apps \
		$(SESSIONS) $(BASHC) $(FISHC) $(ZSHC)
	cd src && find . -type f \( -name '*.qml' -o -name '*.js' -o -name '*.json' \) ! -name 'dev-*' \
		-exec install -Dm644 {} $(SHARE)/{} \;
	sed 's|^here=.*|here=$(PREFIX)/bin|' bin/ssh-shell > $(BIN)/ssh-shell && chmod 755 $(BIN)/ssh-shell
	install -m755 bin/ssh-session $(BIN)/ssh-session
	for s in hyprland niri; do \
		sed 's|@BINDIR@|$(RUNTIME_BINDIR)|g' data/sessions/ssh-$$s.desktop.in > $(SESSIONS)/ssh-$$s.desktop; \
		chmod 644 $(SESSIONS)/ssh-$$s.desktop; done
	install -m644 data/completions/ssh-shell.bash $(BASHC)/ssh-shell
	install -m644 data/completions/ssh-shell.fish $(FISHC)/ssh-shell.fish
	install -m644 data/completions/_ssh-shell $(ZSHC)/_ssh-shell
	install -m644 README.md CHANGELOG.md $(DOC)/
	cp -r docs $(DOC)/
	install -m644 LICENSE $(LIC)/LICENSE
	install -m644 assets/branding/ssh-icon.svg $(ICONS)/scalable/apps/ssh-shell.svg
	install -m644 assets/branding/ssh-icon-256.png $(ICONS)/256x256/apps/ssh-shell.png

uninstall:
	rm -rf $(SHARE) $(DOC) $(LIC)
	rm -f $(BIN)/ssh-shell $(BIN)/ssh-session $(ICONS)/scalable/apps/ssh-shell.svg $(ICONS)/256x256/apps/ssh-shell.png
	rm -f $(SESSIONS)/ssh-hyprland.desktop $(SESSIONS)/ssh-niri.desktop
	rm -f $(BASHC)/ssh-shell $(FISHC)/ssh-shell.fish $(ZSHC)/_ssh-shell
