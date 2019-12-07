#!/bin/bash
set -e

export LC_ALL=C
trap 'kill -- -$(ps -o pgid= $PID | grep -o [0-9]*)' EXIT
options=$(getopt -n inotifywait -o hme: -l help -- "$@" && true)
eval set -- "${options}"
#echo "options: ${options}"

usage () {
    cat <<'EOF'
inotifywait 3.14
Wait for a particular event on a file or set of files.
Usage: inotifywait [ options ] file1 [ file2 ] [ file3 ] [ ... ]
Options:
	-h|--help     	Show this help text.
	@<file>       	Exclude the specified file from being watched.
	--exclude <pattern>
	              	Exclude all events on files matching the
	              	extended regular expression <pattern>.
	--excludei <pattern>
	              	Like --exclude but case insensitive.
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
	-q|--quiet    	Print less (only print events).
	-qq           	Print nothing (not even events).
	--format <fmt>	Print using a specified printf-like format
	              	string; read the man page for more details.
	--timefmt <fmt>	strftime-compatible format string for use with
	              	%T in --format string.
	-c|--csv      	Print events in CSV format.
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

while true; do
    case "$1" in
        -e) shift; events=$1 ;;
        -h|--help) usage ;;
        --) shift; break ;;
    esac
    shift
done

if [[ -z "$1" ]]; then
    echo "No files specified to watch!"
    exit 1
fi

#echo "events: ${events}"

>&2 echo "Setting up watches."

watch () {
    #echo "watch $1"
    find $1 -printf "%s %y %p\\n" | sort -k3 - > $1.inotifywait
    while true; do
        sleep 2
        sign=
        last=$(cat $1.inotifywait)
        find $1 -printf "%s %y %p\\n" | sort -k3 - > $1.inotifywait
        meta=$(diff <(echo "${last}") <(cat "$1.inotifywait")) && true
        [[ -z "${meta}" ]] && continue
        echo -e "${meta}\n." | while IFS= read line || [[ -n "${line}" ]]; do
            #echo "line: $line"
            if [[ "${line}" == "." ]]; then
                #echo "sign: ${sign}"
                for item in $(tr ';' '\n' <<< "${sign}"); do
                    event=$(echo ${item} | cut -s -d':' -f1)
                    focus=$(echo ${item} | cut -s -d':' -f2)
                    dir=$(dirname "${focus}")/
                    file=$(basename "${focus}")
                    echo "${dir} ${event} ${file}"
                done
                break
            fi
            flag=$(echo ${line} | cut -s -d' ' -f1)
            file=$(echo ${line} | cut -s -d' ' -f4)
            [[ -n "${file}" ]] || continue
            #echo ${file: -12}
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
                    fi
                    ;;
            esac
            sign+="${event}:${file};"
        done
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
