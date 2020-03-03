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
}

after_real () {
    killall -w -q inotifywait && true
    return 0
}

before_fake () {
    rm -fr test/temp/fixtures
    cp -R test/fixtures test/temp
}

after_fake () {
    sleep 2
    [[ -z "$(jobs -p)" ]] || kill $(jobs -p)
    sleep 3
}

assert_stdout_stderr () {
    echo "---> stdout test"
    diff $1 test/temp/stdout_real.txt test/temp/stdout_fake.txt && echo "Done."
    echo "---> stderr test"
    diff test/temp/stderr_real.txt test/temp/stderr_fake.txt && echo "Done."
}

success () {
    echo "Test '$1' ok!"
}
