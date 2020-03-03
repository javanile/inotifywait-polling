#!/bin/bash
set -e

#trap 'jobs -p && kill $(jobs -p)' EXIT

source test/testcase.sh

options="-e CREATE -m test/temp/fixtures/a"
trigger_test_events () {
    echo "new-file" > test/temp/fixtures/a/new-file.txt
    return 0
}

before_real
(inotifywait ${options[0]} > test/temp/stdout_real.txt 2> test/temp/stderr_real.txt)&
sleep 1 && trigger_test_events
after_real

before_fake
(./inotifywait-polling.sh ${options[0]} > test/temp/stdout_fake.txt 2> test/temp/stderr_fake.txt)&
sleep 1 && trigger_test_events
after_fake

assert_stdout_stderr

success $0
