#!/bin/bash
set -e

temp () {
    temp=$(dirname "$0")/temp
    [[ -d ${temp} ]] && rm -fr ${temp}
    mkdir -p ${temp}
    echo ${temp}
    return 0
}

success () {
    echo "Test '$1' successful."
}