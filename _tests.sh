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
    git artifact reset
    cd ..
}

echo  "Running testcases; You can find run details for each test in <test>/run.log"
echo

export test="1"
testcase_synopsis="base-repo ; clone; "
{
    cd $test
    generate_base_repo
    git -C $local_tester_repo log --graph --all --oneline --decorate --format="%d %s" > git-test.log
} > ${test}/run.log 2>&1 
diff git-test.log git-reference.log || {
    echo "ERROR: Test $test failed"
    exit 1
}
echo "INFO: Test $test pass: ${testcase_synopsis}"
cd $root_folder

export test="2"
testcase_synopsis="base-repo ; clone; fetch-co : the repo has two tags and the latest is checked out"
{
    cd $test
    generate_base_repo
    git artifact clone --url=$(pwd)/$remote_tester_repo --path $clone_tester_repo
    cd $clone_tester_repo
    git artifact fetch-co -t v1.0
    git artifact fetch-co -t v2.0
} > ${test}/run.log 2>&1 
git log --graph --all --oneline --decorate --format="%d %s" > ../git-test.log
cd ..
diff git-test.log git-reference.log || {
    echo "ERROR: Test $test failed"
    exit 1
}
echo "INFO: Test $test pass: ${testcase_synopsis}"
cd $root_folder

export test="3"
testcase_synopsis="base-repo ; clone - gives a repo without any artifacts"
{
    cd $test
    generate_base_repo "latest"
    git artifact clone --url=$(pwd)/$remote_tester_repo --path $clone_tester_repo
    git -C $clone_tester_repo log --graph --all --oneline --decorate --format="%d %s" > git-test.log
} > ${test}/run.log 2>&1 
diff git-test.log git-reference.log || {
    echo "ERROR: Test $test failed"
    exit 1
}
echo "INFO: Test $test pass: ${testcase_synopsis}"
cd $root_folder

test="4"
testcase_synopsis="base-repo ; clone; add-n-push with branch"
{ 
    cd $test
    generate_base_repo
    git artifact clone --url=$(pwd)/$remote_tester_repo -b latest --path $clone_tester_repo
    cd $clone_tester_repo
    touch test$test.txt 
    git artifact add-n-push -t v${test}.0 -b latest
    touch test$test.1.txt 
    git artifact add-n-push -t v${test}.1 -b latest
} > ${test}/run.log 2>&1 
git log --graph --all --oneline --decorate --format="%d %s" > ../git-test.log
cd ..
diff git-test.log git-reference.log || {
    echo "ERROR: Test $test failed"
    exit 1
}
echo "INFO: Test $test pass: ${testcase_synopsis}"
cd $root_folder

test="5"
testcase_synopsis="base-repo ; clone; fetch-co-latest pattern"
{ 
    cd $test
    generate_base_repo
    git artifact clone --url=$(pwd)/$remote_tester_repo --path $clone_tester_repo
    cd $clone_tester_repo
    git artifact fetch-co-latest -r 'v[0-9]+.[0-9]+'
    git artifact reset
    touch test$test.txt 
    git artifact add-n-push -t v${test}.0
    git tag -d v${test}.0
    git artifact fetch-co-latest -r 'v[0-9]+.[0-9]+'
    git artifact reset
    touch test$test.1.txt 
    git artifact add-n-push -t v${test}.1
    sleep 1
    git tag -d v${test}.1
    git artifact fetch-co-latest --regex 'v[0-9]+.[0-9]+'
} > ${test}/run.log 2>&1 || cat ${test}/run.log
git log --graph --all --oneline --decorate --format="%d %s" > ../git-test.log
cd ..
diff git-test.log git-reference.log || {
    echo "ERROR: Test $test failed: ${testcase_synopsis}"
    exit 1
}
echo "INFO: Test $test pass: ${testcase_synopsis}"
cd $root_folder
