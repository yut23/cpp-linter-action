#!/bin/bash

# save current location
REPO_PATH=$(pwd)

cp /usr/bin/run-clang-tidy.py $INPUT_BUILD_PATH

cd $INPUT_BUILD_PATH
# make the compile command database using bear
bear -- make $INPUT_MAKE_OPTIONS || exit $?

clang-tidy --version
python3 run-clang-tidy.py -header-filter=$INPUT_HEADER_FILTER -ignore-files=$INPUT_IGNORE_FILES -j 2 -config-file=$GITHUB_WORKSPACE/.clang-tidy > $GITHUB_WORKSPACE/clang-tidy-report.txt

cd $REPO_PATH

cppcheck_ignores=()
# extract the directories to ignore from INPUT_IGNORE_FILES (split on '|')
IFS='|' read -ra ignore_files <<<"$INPUT_IGNORE_FILES"
for file in "${ignore_files[@]}"; do
  # after checking the source code, -i also accepts globs
  cppcheck_ignores+=(-i "*/$file/*")
done

cppcheck --enable=all --force --std=c++11 --language=c++ --project=$INPUT_BUILD_PATH/compile_commands.json "${cppcheck_ignores[@]}" --output-file=$GITHUB_WORKSPACE/cppcheck-report.txt
