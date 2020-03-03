#!/bin/bash
set -e

./test/no-args-test.sh
./test/no-events-test.sh

./test/create-no-filters-test.sh
./test/create-test.sh
./test/create-with-close-filter-test.sh
#./test/create-with-touch-file-test.sh

./test/modify-test.sh

./test/moved-to-advanced-test.sh

./test/help-test.sh
