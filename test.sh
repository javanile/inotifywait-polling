#!/bin/bash
set -e
test=$(dirname "$0")/test

## Run all tests
${test}/create-test.sh
