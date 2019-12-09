#!/bin/bash
#set -e

workdir=$(dirname "$0")
test=${workdir}/test
stop=$(cat /proc/sys/kernel/random/uuid)
export PS4='+:$0:$LINENO: '
trap '$(jobs -p) || kill $(jobs -p)' EXIT

lcov_init () {
    mkdir -p coverage
    lcov_scan $0 > coverage/lcov.info
    find . -type f -name "*.sh" | while read file; do
        lcov_scan ${file} > coverage/temp.info
        lcov -q -a coverage/temp.info -a coverage/lcov.info -o coverage/lcov.info
    done
}

lcov_scan () {
    lineno=0
    echo "TN:"
    echo "SF:$1"
    while IFS= read line || [[ -n "${line}" ]]; do
        lineno=$((lineno + 1))
        [[ -z "${line}" ]] && continue
        [[ "${line::1}" == "#" ]] && continue
        echo "DA:${lineno},0"
    done < $1
    echo "end_of_record"
}

lcov_done () {
    genhtml -q -o coverage coverage/lcov.info
}

run_test () {
    rm -f coverage/temp.info
    bash -x $1 2> coverage/test.debug
    echo "${stop}" >> coverage/test.debug
    while IFS= read line || [[ -n "${line}" ]]; do
        if [[ "${line::1}" == "+" ]]; then
            file=$(echo ${line} | cut -s -d':' -f2)
            lineno=$(echo ${line} | cut -s -d':' -f3)
            echo -e "TN:\nSF:$1\nDA:${lineno},1\nend_of_record" >> coverage/temp.info
        elif [[ "${line}" == "${stop}" ]]; then
            echo "STOP"
            lcov -q -a coverage/temp.info -a coverage/lcov.info -o coverage/lcov.info
        fi
    done < coverage/test.debug
}

lcov_init

run_test ${test}/help-test.sh

lcov_done