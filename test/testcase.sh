#!/bin/bash
set -e

before_real () {
    rm -fr test/temp
    mkdir -p test/temp
    cp -R test/fixtures test/temp
}

after_real () {
    killall -w -q inotifywait
}

before_fake () {
    rm -fr test/temp/fixtures
    cp -R test/fixtures test/temp
}

after_fake () {
    sleep 2
    kill $(jobs -p)
    sleep 3
}

assert_stdout_stderr () {
    echo "---> stdout test"
    diff test/temp/stdout_real.txt test/temp/stdout_fake.txt && echo "Done."
    echo "---> stderr test"
    diff test/temp/stderr_real.txt test/temp/stderr_fake.txt && echo "Done."
}

success () {
    echo "Test '$1' ok!"
}
