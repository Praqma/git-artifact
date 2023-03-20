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

function testcase_header() {
    [[ ${verbose:-} == true ]] || return 0
    echo
    echo "--------------------------------------------------------------------------------"
    echo " Testcase begin: ${test} : $testcase_synopsis"
    echo "--------------------------------------------------------------------------------"
}


function eval_testcase() {
    # expect to be in repo to test against
    git log --graph --all --oneline --decorate --format="%d %s" > "${root_folder}/${test}/git-test.log"
    cd "${root_folder}/${test}"
    if diff -Z git-test.log git-reference.log ; then 
        if [[ ${verbose:-} == true ]] ; then 
            cat git-test.log
            echo "INFO: Test $test : OK"
            echo
        else
            echo "INFO: Test $test : OK : ${testcase_synopsis}"
        fi
    else
        echo "ERROR: Test $test failed: ${testcase_synopsis}"
        exit 1
    fi
    cd "${root_folder}"
}

function generate_base_repo() {
    rm -rf "$local_tester_repo/" "$remote_tester_repo/" "$clone_tester_repo/"
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
testcase_synopsis="base-repo ; clone"
testcase_header
{
    cd $test
    generate_base_repo
    cd $local_tester_repo
} > ${test}/run.log 2>&1 
eval_testcase

export test="2"
testcase_synopsis="base-repo ; clone; fetch-co : the repo has two tags and the latest is checked out"
testcase_header
{
    cd $test
    generate_base_repo
    git artifact clone --url=$(pwd)/$remote_tester_repo --path $clone_tester_repo
    cd $clone_tester_repo
    git artifact fetch-co -t v1.0
    git artifact fetch-co -t v2.0
} > ${test}/run.log 2>&1 
eval_testcase

export test="3"
testcase_synopsis="base-repo ; clone - gives a repo without any artifacts"
testcase_header
{
    cd $test
    generate_base_repo "latest"
    git artifact clone --url=$(pwd)/$remote_tester_repo --path $clone_tester_repo
    cd  $clone_tester_repo 
} > ${test}/run.log 2>&1 
eval_testcase

test="4"
testcase_synopsis="base-repo ; clone; add-n-push with branch"
testcase_header
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
eval_testcase

test="5"
testcase_synopsis="base-repo ; clone; fetch-co-latest pattern"
testcase_header
{ 
    cd $test
    generate_base_repo
    git artifact clone --url=$(pwd)/$remote_tester_repo --path $clone_tester_repo
    cd $clone_tester_repo
    git artifact fetch-co-latest -r 'v[0-9]+.[0-9]+'
    git artifact reset
    
    cd ../$local_tester_repo
    touch test$test.txt 
    git artifact add-n-push -t v${test}.0
    sleep 1
    
    cd ../$clone_tester_repo
    git artifact fetch-co-latest -r 'v[0-9]+.[0-9]+'
    git artifact reset
    sleep 1

    cd ../$local_tester_repo
    touch test$test.1.txt 
    git artifact add-n-push -t v${test}.1
    sleep 1

    cd ../$clone_tester_repo
    git artifact fetch-co-latest --regex 'v[0-9]+.[0-9]+'

} > ${test}/run.log 2>&1 || cat ${test}/run.log
eval_testcase

test="6"
testcase_synopsis="base-repo ; clone; fetch-tags"
testcase_header
{ 
    cd $test
    generate_base_repo
    git artifact clone --url=$(pwd)/$remote_tester_repo -b latest --path $clone_tester_repo
    cd $clone_tester_repo
    git artifact fetch-co --tag v1.0
    sha1=$(git rev-parse HEAD)
    git tag -d v1.0
    git artifact fetch-tags --sha1 "$sha1"
} > ${test}/run.log 2>&1 || cat ${test}/run.log
eval_testcase
