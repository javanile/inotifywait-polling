#!/bin/bash
set -e

source test/testcase.sh

options="-e CLOSE -m test/temp/fixtures/a"
trigger_test_events () {
    sleep 1
    echo "new-file" > test/temp/fixtures/a/new-file.txt
    sleep 1
    return 0
}

before_real
(inotifywait ${options[0]} > ${STDOUT_REAL} 2> ${STDERR_REAL})&
trigger_test_events
after_real

before_fake
(./inotifywait-polling.sh ${options[0]} > ${STDOUT_FAKE} 2> ${STDERR_FAKE})&
trigger_test_events
after_fake

assert_stdout_stderr

success $0
