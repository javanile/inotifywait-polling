#!/bin/bash
set -e

source $(dirname "$0")/testcase.sh

options="--help"

inotifywait ${options[0]} > out1.txt && true
./inotifywait-polling.sh ${options[0]} > out2.txt && true

diff err1.txt err2.txt
diff -b out1.txt out2.txt
