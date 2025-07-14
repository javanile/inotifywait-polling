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
	-i|--interval	Sets the polling interval. Defaults to 2 secs. (Unit: sec)
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
options=$(getopt -n inotifywait -o qrhmw:e:i: -l help -- "$@" && true)
eval set -- "${options}"
#echo "options: ${options}"

while true; do
    case "$1" in
        -q) quiet=1 ;;
        -r) recursive=1 ;;
        -i) shift; interval=${1} ;;
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
DIFF_FORMAT=(
    "%s %y %i %p"
    "size type inode path"
)
WATCHTOWER_SUFFIX=".inotifywait"
DEFAULT_INTERVAL=2

init() {
    unset created_items
    unset deleted_items
    declare -A created_items
    declare -A deleted_items
}

watch () {
    target=$1
    [[ -z "${watchtower}" ]] && watchtower="${HOME}"
    [[ "${watchtower}" != */ ]] && watchtower="${watchtower}/"
    watchtower="${watchtower}.$(echo $target | sed -e 's|\.||g' -e 's|^./||g; s|^/||g' -e 's|/$||g' | sed -e 's|/|-|g')${WATCHTOWER_SUFFIX}"

    find $target -printf "${DIFF_FORMAT[0]}\\n" > "${watchtower}"
    while true; do
        sleep "${interval}"
        init

        last=$(cat "${watchtower}")
        find $target -printf "${DIFF_FORMAT[0]}\\n" > "${watchtower}"

        meta=$(diff <(echo "${last}") <(cat "${watchtower}")) && true
        [[ -z "${meta}" ]] && continue
        echo -e "${meta}\n." | while IFS= read line || [[ -n "${line}" ]]; do
            if [[ "${line}" == "." ]]; then
                for _inode in "${!deleted_items[@]}"; do
                    deleted_item="${deleted_items[$_inode]}"
                    created_item="${created_items[$_inode]}"

                    dir="$(dirname "${deleted_item}")/"
                    source="$(basename "${deleted_item}")"
                    destination="$(basename "${created_item}")"

                    if [[ ! -n "${destination}" ]]; then
                        print_event "${dir}" "DELETE" "${source}"
                    elif [[ "${deleted_item}" == "${created_item}" ]]; then
                        unset created_items[$_inode]
                        print_event "${dir}" "MODIFY" "${source}"
                    else
                        unset created_items[$_inode]
                        print_event "${dir}" "MOVE_FROM" "${source}"
                        print_event "${dir}" "MOVE" "${source}" "${destination}"
                        print_event "${dir}" "MOVE_TO" "${destination}"
                    fi
                done
                for _inode in "${!created_items[@]}"; do
                    created_item="${created_items[$_inode]}"

                    dir="$(dirname "${created_item}")/"
                    file="$(basename "${created_item}")"

                    print_event "${dir}" "CREATE" "${file}"
                done
                break
            fi

            read -r flag ${DIFF_FORMAT[1]} <<< "${line}"
            [[ -n "${path}" ]] || continue
            [[ "${path: -${#WATCHTOWER_SUFFIX}}" == "${WATCHTOWER_SUFFIX}" ]] && continue
            case ${flag} in
                "<")
                    deleted_items[$inode]="${path}"
                    ;;
                ">")
                    created_items[$inode]="${path}"
                    ;;
            esac
        done
    done
    return 0
}

##
#
##
print_event () {
    [[ -z "${events}" || "${events}" == *"$2"* ]] && echo "$1 $2 $3 $4"
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
    [[ -z ${interval} ]] && interval="${DEFAULT_INTERVAL}"
    if ! [[ ${interval} =~ ^[0-9]+$ ]] ; then
        echo "Interval is not a number: ${interval}"
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
