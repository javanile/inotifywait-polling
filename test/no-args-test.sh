#!/bin/bash
set -e
source $(dirname "$0")/testcase.sh
cd $(temp)

##
options=

## Run inotifywait
rm -fr fixtures && cp -R ../fixtures .
inotifywait ${options[0]} > out1.txt 2> err1.txt && true

## Run inotifywait
rm -fr fixtures && cp -R ../fixtures .
../../inotifywait-polling.sh ${options[0]} > out2.txt 2> err2.txt && true

## Assert
echo "=== Assert stderr ==="
diff err1.txt err2.txt
echo "=== Assert stdout ==="
diff out1.txt out2.txt
