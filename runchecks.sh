#!/bin/bash

# save current location
REPO_PATH=$(pwd)
ls $HOME

cp /usr/bin/run-clang-tidy.py $INPUT_BUILD_PATH

cd $INPUT_BUILD_PATH
# make the compile command database using bear
bear make $INPUT_MAKE_OPTIONS

clang-tidy --version
python3 run-clang-tidy.py -header-filter='.*' -ignore-files=$INPUT_IGNORE_FILES -j 2 -checks='bugprone-*,performance-*,readability-*,portability-*,modernize-*,clang-analyzer-*,cppcoreguidelines-*' 2>&1 | tee $GITHUB_WORKSPACE/clang-tidy-report.txt

cd $REPO_PATH
find . -regex '.*\.\(cpp\|h\|H\)' | xargs clang-format --style=llvm -i 2>&1 | tee $GITHUB_WORKSPACE/clang-format-report.txt

cppcheck --enable=all --force --std=c++11 --language=c++ --output-file=$GITHUB_WORKSPACE/cppcheck-report.txt *

# cd $GITHUB_WORKSPACE

# PAYLOAD_TIDY=`cat clang-tidy-report.txt`
# PAYLOAD_FORMAT=`cat clang-format-report.txt`
# PAYLOAD_CPPCHECK=`cat cppcheck-report.txt`
  
# echo "Clang-tidy errors:"
# echo $PAYLOAD_TIDY
# echo "Clang-format errors:"
# echo $PAYLOAD_FORMAT
# echo "Cppcheck errors:"
# echo $PAYLOAD_CPPCHECK
