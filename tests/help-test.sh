#!/bin/bash
set -e

## Prepare temp dir
temp=$(dirname "$0")/temp
[[ -d ${temp} ]] && rm -fr ${temp}
mkdir -p ${temp}
cd ${temp}

##
options="--help"

## Run inotifywait
rm -fr fixtures && cp -R ../fixtures .
inotifywait ${options[0]} > out1.txt 2> err1.txt

## Run inotifywait
rm -fr fixtures && cp -R ../fixtures .
../../inotifywait-polling.sh ${options[0]} > out2.txt 2> err2.txt

## Assert
echo "=== Assert stderr ==="
diff err1.txt err2.txt
echo "=== Assert stdout ==="
diff out1.txt out2.txt
