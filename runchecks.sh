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
python3 $GITHUB_WORKSPACE/run-clang-tidy.py -header-filter='.*' -ignore-files=$INPUT_IGNORE_FILES -checks='bugprone-*,performance-*,readability-*,portability-*,modernize-*,clang-analyzer-*,cppcoreguidelines-*' > clang-tidy-report.txt
# clang-tidy *.c *.h *.cpp *.hpp *.C *.cc *.CPP *.c++ *.cp *.cxx *.H -checks=boost-*,bugprone-*,performance-*,readability-*,portability-*,modernize-*,clang-analyzer-cplusplus-*,clang-analyzer-*,cppcoreguidelines-* > clang-tidy-report.txt

cd $REPO_PATH
find . -regex '.*\.\(cpp\|h\|H\)' | xargs clang-format --style=llvm -i > clang-format-report.txt

cppcheck --enable=all --force --std=c++11 --language=c++ --output-file=cppcheck-report.txt *

PAYLOAD_TIDY=`cat clang-tidy-report.txt`
PAYLOAD_FORMAT=`cat clang-format-report.txt`
PAYLOAD_CPPCHECK=`cat cppcheck-report.txt`
COMMENTS_URL=$(cat $GITHUB_EVENT_PATH | jq -r .pull_request.comments_url)
  
echo $COMMENTS_URL
echo "Clang-tidy errors:"
echo $PAYLOAD_TIDY
echo "Clang-format errors:"
echo $PAYLOAD_FORMAT
echo "Cppcheck errors:"
echo $PAYLOAD_CPPCHECK

OUTPUT=$'**CLANG-TIDY WARNINGS**:\n'
OUTPUT+=$'\n```\n'
OUTPUT+="$PAYLOAD_TIDY"
OUTPUT+=$'\n```\n'

OUTPUT=$'**CLANG-FORMAT WARNINGS**:\n'
OUTPUT+=$'\n```\n'
OUTPUT+="$PAYLOAD_FORMAT"eCTF20/mb/drm_audio_fw/src on
OUTPUT+=$'\n```\n'

OUTPUT+=$'\n**CPPCHECK WARNINGS**:\n'
OUTPUT+=$'\n```\n'
OUTPUT+="$PAYLOAD_CPPCHECK"
OUTPUT+=$'\n```\n' 

PAYLOAD=$(echo '{}' | jq --arg body "$OUTPUT" '.body = $body')

curl -s -S -H "Authorization: token $INPUT_GITHUB_TOKEN" --header "Content-Type: application/vnd.github.VERSION.text+json" --data "$PAYLOAD" "$COMMENTS_URL"
