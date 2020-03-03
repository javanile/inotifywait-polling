#!/bin/bash
set -e

STDERR_REAL=test/temp/stderr_real.txt
STDERR_FAKE=test/temp/stderr_fake.txt
STDOUT_REAL=test/temp/stdout_real.txt
STDOUT_FAKE=test/temp/stdout_fake.txt

before_real () {
    rm -fr test/temp
    mkdir -p test/temp
    cp -R test/fixtures test/temp
    sleep 1
}

after_real () {
    sleep 2
    killall -w -q inotifywait && true
    sleep 1
    return 0
}

before_fake () {
    export LCOV_DEBUG=
    rm -fr test/temp/fixtures
    cp -R test/fixtures test/temp
}

after_fake () {
    sleep 2
    [[ -z "$(jobs -p)" ]] || kill $(jobs -p)
    sleep 3
    export LCOV_DEBUG=1
}

assert_stdout_stderr () {
    echo "---> stdout test"
    diff $1 test/temp/stdout_real.txt test/temp/stdout_fake.txt
    echo "---> stderr test"
    diff test/temp/stderr_real.txt test/temp/stderr_fake.txt
}

success () {
    echo "Test '$1' ok!"
}
