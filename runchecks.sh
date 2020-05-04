#!/bin/bash

if [[ -z "$INPUT_GITHUB_TOKEN" ]]; then
	echo "The GITHUB_TOKEN is required."
	exit 1
fi

# FILES_LINK=`jq -r '.pull_request._links.self.href' "$GITHUB_EVENT_PATH"`/files
# echo "Files = $FILES_LINK"

# curl $FILES_LINK > files.json
# FILES_URLS_STRING=`jq -r '.[].raw_url' files.json`

# readarray -t URLS <<<"$FILES_URLS_STRING"

# echo "File names: $URLS"

# mkdir files
# cd files
# for i in "${URLS[@]}"
# do
#    echo "Downloading $i"
#    curl -LOk --remote-name $i 
# done

# echo "Files downloaded!"

# save current location
REPO_PATH=$(pwd)

echo "Performing checkup:"
cd $INPUT_BUILD_PATH
# make the compile command database using bear
bear make $INPUT_MAKE_OPTIONS

clang-tidy --version
python3 $GITHUB_WORKSPACE/run-clang-tidy.py -header-filter='.*' -ignore-files=$INPUT_IGNORE_FILES -j 2 -checks='bugprone-*,performance-*,readability-*,portability-*,modernize-*,clang-analyzer-*,cppcoreguidelines-*' > $GITHUB_WORKSPACE/clang-tidy-report.txt
# clang-tidy *.c *.h *.cpp *.hpp *.C *.cc *.CPP *.c++ *.cp *.cxx *.H -checks=boost-*,bugprone-*,performance-*,readability-*,portability-*,modernize-*,clang-analyzer-cplusplus-*,clang-analyzer-*,cppcoreguidelines-* > clang-tidy-report.txt

cd $REPO_PATH
find . -regex '.*\.\(cpp\|h\|H\)' | xargs clang-format --style=llvm -i > $GITHUB_WORKSPACE/clang-format-report.txt

cppcheck --enable=all --force --std=c++11 --language=c++ --output-file=$GITHUB_WORKSPACE/cppcheck-report.txt *

cd $GITHUB_WORKSPACE

PAYLOAD_TIDY=`cat clang-tidy-report.txt`
PAYLOAD_FORMAT=`cat clang-format-report.txt`
PAYLOAD_CPPCHECK=`cat cppcheck-report.txt`
  
echo $COMMENTS_URL
echo "Clang-tidy errors:"
echo $PAYLOAD_TIDY
echo "Clang-format errors:"
echo $PAYLOAD_FORMAT
echo "Cppcheck errors:"
echo $PAYLOAD_CPPCHECK
