#!/bin/bash
set -e

source test/testcase.sh

options=

before_real
inotifywait ${options[0]} > ${STDOUT_REAL} 2> ${STDERR_REAL} && true
after_real

before_fake
./inotifywait-polling.sh ${options[0]} > ${STDOUT_FAKE} 2> ${STDERR_FAKE} && true
after_fake

assert_stdout_stderr

success $0
