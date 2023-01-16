#!/bin/bash

clear 

set -euo pipefail
[[ ${debug:-} == true ]] && set -x
PATH=$(pwd):$PATH

cd .test
root_folder=$(pwd)

local_tester_repo=.local
remote_tester_repo=.remote
clone_tester_repo=.clone

function generate_base_repo() {
    rm -rf $local_tester_repo/ $remote_tester_repo/ $clone_tester_repo/
    git init --bare $remote_tester_repo
    git artifact init --url=$(pwd)/$remote_tester_repo --path $local_tester_repo
    cd $local_tester_repo
    touch test.txt
    git artifact add-n-push -t v1.0
    sleep 1
    touch test2.txt
    git artifact add-n-tag -t v2.0
    git artifact push -t v2.0
    cd ..
}

export test="1"
cd $test
generate_base_repo
git -C $local_tester_repo log --graph --all --oneline --decorate --format="%d %s" > git-test.log
diff git-test.log git-reference.log || {
    echo "ERROR: Test failed"
    exit 1
}
cd $root_folder

export test="2"
cd $test
generate_base_repo
git artifact clone --url=$(pwd)/$remote_tester_repo --path $clone_tester_repo
cd $clone_tester_repo
git artifact fetch-co -t v1.0
git artifact fetch-co -t v2.0
git log --graph --all --oneline --decorate --format="%d %s" > ../git-test.log
cd ..
diff git-test.log git-reference.log || {
    echo "ERROR: Test failed"
    exit 1
}
cd $root_folder

export test="3"
cd $test || {
    mkdir $test
    cd $test
}
generate_base_repo
git artifact clone --url=$(pwd)/$remote_tester_repo --path $clone_tester_repo
git -C $clone_tester_repo log --graph --all --oneline --decorate --format="%d %s" > ../git-test.log
cd ..
diff git-test.log git-reference.log || {
    echo "ERROR: Test failed"
    exit 1
}
cd $root_folder
