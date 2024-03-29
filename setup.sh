#!/bin/bash
set -e

##
# inotifywait-polling v0.0.1
# --------------------------
# by Francesco Bianco
# info@javanile.org
# MIT License
##

FILE_BIN=${bin:-/usr/local/bin/inotifywait-polling}
FILE_SRC=https://raw.githubusercontent.com/javanile/inotifywait-polling/main/inotifywait-polling.sh

echo "Get: ${FILE_SRC} -> ${FILE_BIN}"
curl --progress-bar -sLo ${FILE_BIN} ${FILE_SRC}

echo "Inf: apply executable permission to ${FILE_BIN}"
chmod +x ${FILE_BIN}

echo "Done."
