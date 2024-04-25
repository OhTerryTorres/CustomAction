#!/bin/bash
set -e

if [ -n "$GITHUB_EVENT_PATH" ];
then
    EVENT_PATH=$GITHUB_EVENT_PATH
elif [ -f ./sample_push_event.json ];
then
    EVENT_PATH='./sample_push_event.json'
    LOCAL_TEST=true
else
    echo "No JSON data to process! :("
    exit 1
fi

env
jq . < $EVENT_PATH

# if keyword is found
if jq '.commits[].message, .head_commit.message' < $EVENT_PATH | grep -i -q "$*";
then
    # do something
    VERSION=$(date +%F.%s)
    
    DATA="$(printf 'tag_name="%s" target_commitish="main" name="%s" body="An automated release based on keyword: %s" draft=false prerelease=false' $VERSION, $VERSION, $*)"

    URL="https://api.github.com/repos/${GITHUB_REPOSITORY}/releases"

    curl -L -k \
        -X POST \
        -H "Accept: application/vnd.github+json" \
        -H "Authorization: Bearer ${GITHUB_TOKEN}" \
        -H "X-GitHub-Api-Version: 2022-11-28" \
        ${URL} \
        -d "$(printf '{"tag_name":"v%s","target_commitish":"main","name":"%s","body":"An automated release based on keyword: %s","draft":false,"prerelease":false,"generate_release_notes":false}' $VERSION, $VERSION, $*)"
# otherwise
else
    # exit gracefully
    echo "Nothing to process."
fi
