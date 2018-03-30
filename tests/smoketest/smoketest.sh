#!/bin/bash

EXIT_CODE=0
GROUP_TOTAL=0
GROUP_SKIPPED=0
GROUP_FAILURE=0
JOBS=1
API_TEST_PATH=../../python_scripts/tests/api_tests
BLOCK_SUBPATH=blockchain/block_log
GROUP_TEST_SCRIPT=test_group.sh

function echo(){ builtin echo $(basename $0 .sh): "$@"; }
pushd () { command pushd "$@" > /dev/null; }
popd () { command popd "$@" > /dev/null; }

function print_help_and_quit {
   echo "Usage: path_to_tested_steemd path_to_reference_steemd path_to_test_blockchain_directory path_to_reference_blockchain_directory number_of_blocks_to_replay"
   echo "Example: ~/work/steemit/steem/build/Release/programs/steemd/steemd ~/master/steemit/steem/build/Release/programs/steemd/steemd ~/steemit/steem/work1 ~/steemit/steem/work2 5000000"
   exit $EXIT_CODE
}

if [ $# -ne 5 ]
then
   print_help_and_quit
fi

TEST_STEEMD_PATH=$1
REF_STEEMD_PATH=$2
TEST_WORK_PATH=$3
REF_WORK_PATH=$4
BLOCK_LIMIT=$5

function check_steemd_path {
   echo Checking $1...
   if [ -x "$1" ] && file "$1" | grep -q "executable"
   then
      echo OK: $1 is executable file.
   else
      echo FATAL: $1 is not executable file or found! && exit -1
   fi
}

function check_work_path {
   echo Checking $1...
   if [ -e "$1" ] && [ -e "$1/$BLOCK_SUBPATH" ]
   then
      echo OK: $1/$BLOCK_SUBPATH found.
   else
      echo FATAL: $1 not found or $BLOCK_SUBPATH not found in $1! && exit -1
   fi
}

function run_test_group {
   echo Running test group $1
   pushd $1

   if ! [ -x "$GROUP_TEST_SCRIPT" ]; then
      echo Skipping subdirectory $1 due to missing $GROUP_TEST_SCRIPT file.
      ((GROUP_SKIPPED++))
      popd
      return
   fi

   echo Running ./$GROUP_TEST_SCRIPT $JOBS $TEST_STEEMD_PATH $REF_STEEMD_PATH $TEST_WORK_PATH $REF_WORK_PATH $BLOCK_LIMIT
   ./$GROUP_TEST_SCRIPT $JOBS $TEST_STEEMD_PATH $REF_STEEMD_PATH $TEST_WORK_PATH $REF_WORK_PATH $BLOCK_LIMIT
   [ $? -ne 0 ] && echo test group $1 FAILED && ((GROUP_FAILURE++)) && EXIT_CODE=-1

   popd
}

check_steemd_path $TEST_STEEMD_PATH
check_steemd_path $REF_STEEMD_PATH

check_work_path $TEST_WORK_PATH
check_work_path $REF_WORK_PATH

for dir in ./*/
do
    dir=${dir%*/}
    run_test_group ${dir##*/}
    ((GROUP_TOTAL++))
done

echo TOTAL test groups: $GROUP_TOTAL
echo SKIPPED test groups: $GROUP_SKIPPED
echo FAILED test groups: $GROUP_FAILURE

exit $EXIT_CODE