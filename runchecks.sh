#!/bin/bash

# save current location
REPO_PATH=$(pwd)

cp /usr/bin/run-clang-tidy.py $INPUT_BUILD_PATH

cd $INPUT_BUILD_PATH
# make the compile command database using bear
echo '::group::Run make to generate a compilation database'
bear -- make $INPUT_MAKE_OPTIONS || exit $?
echo '::endgroup::'

echo '::group::Run clang-tidy'
clang-tidy --version
echo
python3 run-clang-tidy.py -header-filter=$INPUT_HEADER_FILTER -ignore-files=$INPUT_IGNORE_FILES -j 4 -config-file=$GITHUB_WORKSPACE/.clang-tidy > $GITHUB_WORKSPACE/clang-tidy-report.txt
echo '::endgroup::'

# extract -I directories from the compilation database into a shell array
includes=()
eval "$(jq -r 'map(.arguments | map(select(startswith("-I")) | ltrimstr("-I")))
               | flatten | unique
               | @sh "includes=( \(.) )"' compile_commands.json)"

# split on all whitespace (including newlines)
# this avoids expanding globs
read -ra cppcheck_args -d '' <<<"$INPUT_CPPCHECK_OPTIONS"

# extract the directories to ignore from INPUT_IGNORE_FILES (split on '|')
IFS='|' read -ra ignore_files <<<"$INPUT_IGNORE_FILES"
for file in "${ignore_files[@]}"; do
  # after checking the source code, -i also accepts globs
  cppcheck_args+=(-i "*/$file/*")
  # also suppress any errors from the ignored files
  cppcheck_args+=("--suppress=*:*/$file/*")
  # don't scan ignored directories for preprocessor variables
  for include in "${includes[@]}"; do
    if [[ $include = *"/$file/"* ]]; then
      cppcheck_args+=("--config-exclude=$include")
    fi
  done
done

echo '::group::Run cppcheck'
cppcheck --version
echo "extra cppcheck arguments: ${cppcheck_args[*]}"
echo
cppcheck --enable=all --force --std=c++17 --language=c++ --project=compile_commands.json "${cppcheck_args[@]}" --output-file=$GITHUB_WORKSPACE/cppcheck-report.txt
echo '::endgroup::'
