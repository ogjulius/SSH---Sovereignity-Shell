#!/bin/sh
# SSH — Sovereignity Shell installer.
#
#   git clone https://github.com/ogjulius/SSH---Sovereignity-Shell.git
#   cd SSH---Sovereignity-Shell
#   ./install.sh                  (./install.sh --help for options)
#
# Works from any interactive shell (bash, fish, zsh, ...): it only needs bash
# to be installed as an interpreter, which every supported distribution has.
here=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
if ! command -v bash >/dev/null 2>&1; then
    echo "install.sh: bash is required to run the installer (it does not have to be your shell)." >&2
    exit 1
fi
exec bash "$here/installer/ssh-install.sh" "$@"
