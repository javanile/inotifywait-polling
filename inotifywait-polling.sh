#!/bin/bash
set -e

export LC_ALL=C

trap 'kill -- -$(ps -o pgid= $PID | grep -o [0-9]*)' EXIT

options=$(getopt -n inotifywait -o e: -l color: -- "$@" && true)

eval set -- "${options}"

echo "options: ${options}"

while true; do
    case "$1" in
        -e) shift; events=$1 ;;
        --) shift; break ;;
    esac
    shift
done

if [[ -z "$1" ]]; then
    echo "No files specified to watch!"
    exit 1
fi

echo "events: ${events}"

>&2 echo "Setting up watches."

watch () {
    echo "watch $1"
    find $1 -printf "%s %y %p\\n" | sort -k3 - > $1.a.inotifywait
    while true; do
        sleep 1
        find $1 -printf "%s %y %p\\n" | sort -k3 - > $1.b.inotifywait
        diff $1.a.inotifywait $1.b.inotifywait | \
        while IFS= read line || [[ -n "${line}" ]]; do
            flag=$(echo ${line} | cut -s -d' ' -f1)
            file=$(echo ${line} | cut -s -d' ' -f4)
            echo "line: $line"
            [[ -n "${file}" ]] || continue
            #echo ${file: -12}
            [[ "${file: -12}" != ".inotifywait" ]] || continue
            case ${flag} in
                ">") event=CREATE ;;
                "<") event=DELETE ;;
            esac
            echo "$1 ${event} ${file}"
        done
        cp -f $1.b.inotifywait $1.a.inotifywait
    done
}

for file in "$@"; do
    if [[ ! -e "${file}" ]]; then
        echo "Couldn't watch $1: No such file or directory"
        exit 1
    fi
    watch ${file} &
done

>&2 echo "Watches established."
sleep infinity
exit 0
