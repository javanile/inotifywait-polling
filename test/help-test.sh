#!/bin/bash
set -e
source $(dirname "$0")/testcase.sh
cd $(temp)

options="--help"

inotifywait ${options[0]} > out1.txt 2> err1.txt && true
../../inotifywait-polling.sh ${options[0]} > out2.txt 2> err2.txt && true

diff err1.txt err2.txt
diff -b out1.txt out2.txt
