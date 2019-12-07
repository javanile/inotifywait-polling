#!/bin/bash
set -e

## Prepare temp dir
temp=$(dirname "$0")/temp
[[ -d ${temp} ]] && rm -fr ${temp}
mkdir -p ${temp}
cd ${temp}

##
options="-e CREATE -m ./fixtures/a"
process () {
    sleep 1 && echo "new-file" > ./fixtures/a/new-file.txt
    return 0
}

## Run inotifywait
rm -fr fixtures && cp -R ../fixtures .
(inotifywait ${options[0]} > out1.txt 2> err1.txt)&
process

## Run inotifywait
killall -w -q inotifywait
rm -fr fixtures && cp -R ../fixtures .
(../../inotifywait-polling.sh ${options[0]} > out2.txt 2> err2.txt)&
process

## Assert
echo "=== Assert stderr ==="
diff err1.txt err2.txt
echo "=== Assert stdout ==="
diff out1.txt out2.txt
