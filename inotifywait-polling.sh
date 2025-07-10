#!/usr/bin/env bash

##
# inotifywait-polling
#
# inotifywait in full BASH.
#
# Copyright (c) 2020 Francesco Bianco <bianco@javanile.org>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
##

[[ -z "${LCOV_DEBUG}" ]] || set -x

set -e

export LC_ALL=C

#trap '[[ -z "$(jobs -p)" ]] || kill $(jobs -p)' EXIT
trap 'kill $(jobs -p) > /dev/null 2>&1' EXIT

usage () {
    cat <<'EOF'
inotifywait 3.14
Wait for a particular event on a file or set of files.
Usage: inotifywait [ options ] file1 [ file2 ] [ file3 ] [ ... ]
Options:
	-h|--help	 	Show this help text.
	@<file>	   		Exclude the specified file from being watched.
	--exclude <pattern>
				  	Exclude all events on files matching the
				  	extended regular expression <pattern>.
	--excludei <pattern>
				  	Like --exclude but case insensitive.
	-w|--watchtower	Set the file path where monitoring information is stored.
	-m|--monitor  	Keep listening for events forever.  Without
				  	this option, inotifywait will exit after one
				  	event is received.
	-d|--daemon   	Same as --monitor, except run in the background
				  	logging events to a file specified by --outfile.
				  	Implies --syslog.
	-r|--recursive	Watch directories recursively.
	--fromfile <file>
				  	Read files to watch from <file> or `-' for stdin.
	-o|--outfile <file>
				  	Print events to <file> rather than stdout.
	-s|--syslog   	Send errors to syslog rather than stderr.
	-q|--quiet		Print less (only print events).
	-qq		   		Print nothing (not even events).
	--format <fmt>	Print using a specified printf-like format
				  	string; read the man page for more details.
	--timefmt <fmt>	strftime-compatible format string for use with
				  	%T in --format string.
	-c|--csv	  	Print events in CSV format.
	-t|--timeout <seconds>
					When listening for a single event, time out after
					waiting for an event for <seconds> seconds.
					If <seconds> is 0, inotifywait will never time out.
	-e|--event <event1> [ -e|--event <event2> ... ]
		Listen for specific event(s).  If omitted, all events are
		listened for.

Exit status:
	0  -  An event you asked to watch for was received.
	1  -  An event you did not ask to watch for was received
		  (usually delete_self or unmount), or some error occurred.
	2  -  The --timeout option was given and no events occurred
		  in the specified interval of time.

Events:
	access		file or directory contents were read
	modify		file or directory contents were written
	attrib		file or directory attributes changed
	close_write	file or directory closed, after being opened in
				writable mode
	close_nowrite	file or directory closed, after being opened in
				read-only mode
	close		file or directory closed, regardless of read/write mode
	open		file or directory opened
	moved_to	file or directory moved to watched directory
	moved_from	file or directory moved from watched directory
	move		file or directory moved to or from watched directory
	create		file or directory created within watched directory
	delete		file or directory deleted within watched directory
	delete_self	file or directory was deleted
	unmount		file system containing file or directory unmounted
EOF
}

quiet=
recursive=
watchtower=
options=$(getopt -n inotifywait -o qrhmw:e: -l help -- "$@" && true)
eval set -- "${options}"
#echo "options: ${options}"

while true; do
    case "$1" in
        -q) quiet=1 ;;
        -r) recursive=1 ;;
        -w) shift; watchtower=${1} ;;
        -e) shift; events=${1^^} ;;
        -h|--help) usage; exit ;;
        --) shift; break ;;
    esac
    shift
done

##
#
##
watch () {
    [[ -z ${watchtower} ]] && watchtower=$1
    #echo "watch $watchtower"
    find $watchtower -printf "%s %y %p\\n" | sort -k3 - > $watchtower.inotifywait
    while true; do
        sleep 2
        sign=
        last=$(cat $watchtower.inotifywait)
        #mv $watchtower.inotifywait $watchtower.$(date +%s).inotifywait
        find $watchtower -printf "%s %y %p\\n" | sort -k3 - > $watchtower.inotifywait
        meta=$(diff <(echo "${last}") <(cat "$watchtower.inotifywait")) && true
        [[ -z "${meta}" ]] && continue
        echo -e "${meta}\n." | while IFS= read line || [[ -n "${line}" ]]; do
            #echo "line: $line"
            if [[ "${line}" == "." ]]; then
                #echo "sign: $sign"
                for item in $(tr ';' '\n' <<< "${sign}"); do
                    event=$(echo ${item} | cut -s -d':' -f1)
                    focus=$(echo ${item} | cut -s -d':' -f2)
                    dir=$(dirname "${focus}")/
                    file=$(basename "${focus}")
                    print_event ${dir} ${event} ${file}
                done
                break
            fi
            flag=$(echo ${line} | cut -s -d' ' -f1)
            file=$(echo ${line} | cut -s -d' ' -f4)
            [[ -n "${file}" ]] || continue
            #echo "${file} -- ${file: -12}"
            [[ "${file: -12}" != ".inotifywait" ]] || continue
            case ${flag} in
                "<")
                    event=DELETE
                    ;;
                ">")
                    event=CREATE
                    if [[ "${sign}" == *"DELETE:${file};"* ]]; then
                        event=MODIFY
                        sign=$(echo "${sign}" | sed "s#DELETE:${file};##g")
                    elif [[ "${sign}" == *"DELETE:"* ]]; then
                        event=MOVED_TO
                        sign=$(echo "${sign}" | sed "s#DELETE:.*;##g")
                    fi
                    ;;
            esac
            sign+="${event}:${file};"
        done
    done
    return 0
}

##
#
##
print_event () {
    [[ -z "${events}" || "${events}" == *"$2"* ]] && echo "$1 $2 $3"
    case "$2" in
        CREATE)
            [[ -z "${events}" || "${events}" == *"OPEN"* ]] && echo "$1 OPEN $3"
            [[ -z "${events}" || "${events}" == *"MODIFY"* ]] && echo "$1 MODIFY $3"
            [[ -z "${events}" || "${events}" == *"CLOSE"* ]] && echo "$1 CLOSE_WRITE,CLOSE $3"
            ;;
    esac
    return 0
}

##
# Entrypoint
##
main () {
    if [[ -z "$1" ]]; then
        >&2 echo "No files specified to watch!"
        exit 1
    fi

    [[ -z "${quiet}" ]] && >&2 echo "Setting up watches."

    for file in "$@"; do
        if [[ ! -e "${file}" ]]; then
            echo "Couldn't watch $1: No such file or directory"
            exit 1
        fi
        watch ${file} &
    done

    [[ -z "${quiet}" ]] && >&2 echo "Watches established."
    sleep infinity
    exit 0
}

##
main "$@"
