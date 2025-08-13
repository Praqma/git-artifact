#!/usr/bin/env bash
# shellcheck disable=SC2317
# shellcheck disable=SC2329


function usage() {
    cat <<EOF
Usage: $(basename "$0") [options]

Options:
  -h, --help        Show this help message and exit
  -d, --debug           Enable debug mode
  --verbose         Enable verbose output
  -t|--testcase <#> Specify a single test case to run (e.g., 1, 2, 3.1, etc.)

Description:
  This script runs integration tests for git-artifact.
  Each test is located in a numbered subdirectory (e.g., 1, 2, 3, ...).
  To add a new test:
    1. Create a new directory (e.g., '8') inside '.test'.
    2. Add reference logs and expected outputs as needed.
    3. Add a new test block in this script following the examples above.
    4. Use 'testcase_header' and 'eval_testcase' functions for consistency.
    5. Ensure the test directory contains a 'git-reference.log' file with expected output. 
        Default will the git-reference.log file be used as a reference and compared against the output of the test.
        You can generate the git-test.log manually in the test case, if you need different content that the git log
        It could be output from the git artifact command or any other command that produces content to be evaluated. 
    6. Use 'git artifact' commands to interact with the git repository.
    7. Run the script to execute all tests and check results.
    8. Review the output logs in each test directory for success or failure.
    9. git add the git-reference.log file along with your added tests

EOF
}

# Option handling
debug=false
verbose=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        -t|--testcase)
            [[ -z ${2:-} ]] && { 
                echo "Error: --testcase requires an argument" >&2
                exit 1
            }  
            arg_testcase="$2"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        --debug|-d)
            arg_debug=true
            shift
            ;;
        --verbose)
            verbose=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

clear 

set -euo pipefail
PATH=$(pwd):$PATH

source "$(dirname "$0")/git-artifact"
[[ ${arg_debug:-} == true ]] && {
    export debug=true
    export arg_debug=true
    debug "arg_debug: ${arg_debug}"
    debug "debug: ${debug}"
    set -x
}
check_environment

cd .test
root_folder=$(pwd)
echo "Cleaning $(pwd)"
git clean -xffdq .

local_tester_repo=.local
remote_tester_repo=.remote
clone_tester_repo=.clone
global_exit_code=0

function testcase_header() {
    [[ ! -d "${test}" ]] && {
        echo "Creating test directory: ${test} and empty git-reference.log"
        mkdir -p "${test}"
        touch "${test}/git-reference.log"
    }
    [[ ${verbose:-} == true ]] || return 0
    echo
    echo "--------------------------------------------------------------------------------"
    echo " Testcase begin: ${test} : $testcase_synopsis"
    echo "--------------------------------------------------------------------------------"
}

function generate_git_test_log() {
    rm -rf .git/refs/remotes/origin/HEAD
    git log --graph --all --oneline --format="%d %s" >> "${root_folder}/${test}/git-test.log"
}

function eval_testcase() {
    # expect to be in repo to test against
    
    # In git 2.48 changes the way HEAD is handled and for some reason it is not set 
    # in order to be backward compatible we remove the HEAD reference
    
    if ! [[ -s "${root_folder}/${test}/git-test.log" ]]; then
        generate_git_test_log
    else
        [[ ${debug:-} == true ]] && echo "Test $test : INFO: ${root_folder}/${test}/git-test.log is already available - use it"
    fi
    cd "${root_folder}/${test}"
    if diff -w git-reference.log git-test.log ; then 
        if [[ ${verbose:-} == true ]] ; then 
            cat git-test.log
            echo "Test $test : OK"
            echo
        else
            echo "Test $test : OK : ${testcase_synopsis}"
        fi
        mv run.log ok.log
    else
        echo "Test $test : NOK : ${testcase_synopsis}"
        mv run.log nok.log
        [[ ${verbose:-} == true ]] && cat git-test.log
        global_exit_code=2
    fi
    cd "${root_folder}"
    echo
}

function generate_base_repo() {
    rm -rf "${local_tester_repo:?}/" "${remote_tester_repo:?}/" "${clone_tester_repo:?}/"
    git init --bare -b "${default_branch:-main}" $remote_tester_repo || {
        git init --bare $remote_tester_repo
        git -C $remote_tester_repo symbolic-ref HEAD refs/heads/${default_branch:-main}
    }
    git artifact init --url="$(pwd)/$remote_tester_repo" --path $local_tester_repo -b ${default_branch:-main} 
    cd $local_tester_repo
    touch test.txt
    git artifact add-n-push -t v1.0
    sleep 1
    touch test2.txt
    git artifact add-n-tag -t v2.0
    git artifact push -t v2.0
    git artifact reset
    sleep 1
    cd ..
}

echo "Running testcases; You can find run details for each test in:"
echo "  - <test>/run.log(unknown)"
echo "  - <test>/ok.log(all good)"
echo "  - <test>/nok.log(failed tests)"
echo

function 1 {
    export test="1"
    testcase_synopsis="base-repo default-branch; clone"
    testcase_header
    {
        cd $test
        generate_base_repo
        cd $local_tester_repo
    } > ${test}/run.log 2>&1 
    eval_testcase
}

function 1.1 {
    export test="1.1"
    testcase_synopsis="base-repo master-branch; clone"
    testcase_header
    {
        cd $test
        export default_branch=master
        generate_base_repo
        cd $local_tester_repo
        unset default_branch
    } > ${test}/run.log 2>&1 
    eval_testcase
}

function 2 {
    test="${FUNCNAME[0]}"
    testcase_synopsis="base-repo ; clone; fetch-co : the repo has two tags and the latest is checked out"
    testcase_header
    {
        cd $test
        generate_base_repo
        git artifact clone --url "$(pwd)/$remote_tester_repo" --path "$clone_tester_repo"
        cd $clone_tester_repo
        git artifact fetch-co -t v1.0
        git artifact fetch-co -t v2.0
    } > ${test}/run.log 2>&1 
    eval_testcase
}

function 3 {
    test="${FUNCNAME[0]}"
    testcase_synopsis="base-repo ; clone - gives a repo without any artifacts"
    testcase_header
    {
        cd $test
        generate_base_repo "latest"
        git artifact clone --url "$(pwd)/$remote_tester_repo" --path "$clone_tester_repo"
        cd  $clone_tester_repo 
    } > ${test}/run.log 2>&1 
    eval_testcase
}

function 4 {
    export test="4"
    testcase_synopsis="base-repo ; clone; add-n-push with branch"
    testcase_header
    {
        cd $test
        generate_base_repo
        git artifact clone --url "$(pwd)/$remote_tester_repo" -b latest --path "$clone_tester_repo"
        cd $clone_tester_repo
        touch test$test.txt 
        git artifact add-n-push -t v${test}.0 -b latest
        touch test$test.1.txt 
        git artifact add-n-push -t v${test}.1 -b latest
    } > ${test}/run.log 2>&1 
    eval_testcase
}

function 5 {
    test="${FUNCNAME[0]}"
    testcase_synopsis="base-repo ; clone; fetch-co-latest pattern"
    testcase_header
    { 
        cd $test
        generate_base_repo
        sleep 1
        git artifact clone --url "$(pwd)/$remote_tester_repo" --path "$clone_tester_repo"
        cd $clone_tester_repo
        git artifact fetch-co-latest -g 'v*.*'
        git artifact reset
        
        cd ../$local_tester_repo
        touch test$test.txt 
        git artifact add-n-push -t v${test}.0
        sleep 1
        
        cd ../$clone_tester_repo
        git artifact fetch-co-latest -g 'v*.*'
        git artifact reset
        sleep 1

        cd ../$local_tester_repo
        touch test$test.1.txt 
        git artifact add-n-push -t v${test}.1
        sleep 1

        cd ../$clone_tester_repo
        git artifact fetch-co-latest --glob 'v*.*'

    } > ${test}/run.log 2>&1 || { echo "ERROR_CODE: $?";  pwd && cat ../run.log; }
    eval_testcase
}

function 5.1 {
    test="${FUNCNAME[0]}"
    testcase_synopsis="base-repo ; clone; find-latest pattern"
    testcase_header
    { 
        cd $test
        generate_base_repo
        sleep 1
        git artifact clone --url "$(pwd)/$remote_tester_repo" --path "$clone_tester_repo"
        cd $clone_tester_repo
        git ls-remote origin --tags
        git artifact find-latest -g 'v*.*' > ${root_folder}/${test}/git-test.log
    } > ${root_folder}/${test}/run.log 2>&1 || { pwd && cat ${root_folder}/${test}/run.log; }
    eval_testcase
}


function 6 {
    test="${FUNCNAME[0]}"
    testcase_synopsis="base-repo ; clone; fetch-tags"
    testcase_header
    { 
        cd $test
        generate_base_repo
        git artifact clone --url "$(pwd)/$remote_tester_repo" -b latest --path "$clone_tester_repo"
        cd $clone_tester_repo
        git artifact fetch-co --tag v1.0
        sha1=$(git rev-parse HEAD)
        git tag -d v1.0
        git artifact fetch-tags --sha1 "$sha1"
    } > ${test}/run.log 2>&1 || cat ../${test}/run.log
    eval_testcase
}

function 7 {
    test="${FUNCNAME[0]}"
    testcase_synopsis="base-repo ; clone; list"
    testcase_header
    { 
        cd $test
        generate_base_repo
        sleep 1
        git artifact clone --url "$(pwd)/$remote_tester_repo" --path "$clone_tester_repo"
        cd $clone_tester_repo
        git artifact fetch-co-latest -g 'v*.*'
        git artifact reset
        
        cd ../$local_tester_repo
        
        touch test${test}_1.txt
        git artifact add-n-push -t v${test}.1

        generate_git_test_log
        git artifact list --glob 'v*.*' >> ${root_folder}/${test}/git-test.log
    

    } > ${root_folder}/${test}/run.log 2>&1 || { pwd && cat ${root_folder}/${test}/run.log; }
    eval_testcase
}

function 8 {
    test="${FUNCNAME[0]}"
    testcase_synopsis="base-repo ; clone; summary"
    testcase_header
    { 
        cd $test
        generate_base_repo
        sleep 1
        git artifact clone --url "$(pwd)/$remote_tester_repo" --path "$clone_tester_repo"
        cd $clone_tester_repo
        git artifact fetch-co-latest -g 'v*.*'
        git artifact reset
        
        cd ../$local_tester_repo
        
        for i in {1..5}; do
            touch test${test}_$i.txt
            git artifact add-n-push -t test1/v${test}.$i
            sleep 1
        done

        for i in {1..7}; do
            touch test${test}_$i.txt
            git artifact add-n-push -t test2/v${test}.$i
            sleep 1
        done

        generate_git_test_log
        git artifact summary >> ${root_folder}/${test}/git-test.log

    } > ${root_folder}/${test}/run.log 2>&1 || { pwd && cat ${root_folder}/${test}/run.log; }
    eval_testcase
}

function 9 {
    test="${FUNCNAME[0]}"
    
    testcase_synopsis="base-repo ; clone; prune dryrun and prune and list"
    testcase_header
    { 
        cd $test
        generate_base_repo
        sleep 1
        git artifact clone --url "$(pwd)/$remote_tester_repo" --path "$clone_tester_repo"
        cd $clone_tester_repo
        git artifact fetch-co-latest -g 'v*.*'
        git artifact reset
        
        cd ../$local_tester_repo
        
        for i in {1..10}; do
            touch test${test}_$i.txt
            git artifact add-n-push -t v${test}.$i
            sleep 1
        done

        generate_git_test_log
        git artifact prune --glob 'v*.*' --keep 5 --dryrun >> ${root_folder}/${test}/git-test.log
        git artifact prune --glob 'v*.*' --keep 5
        git fetch origin -pP

        generate_git_test_log

        git artifact list --glob 'v*.*' >> ${root_folder}/${test}/git-test.log

    } > ${root_folder}/${test}/run.log 2>&1 || { pwd && cat ${root_folder}/${test}/run.log; }
    eval_testcase
}

function 10 {
    test="${FUNCNAME[0]}"
    
    testcase_synopsis="base-repo ; clone; add-as-submodule"
    testcase_header
    { 
        cd $test
        generate_base_repo
        sleep 1
        git artifact clone --url "$(pwd)/$remote_tester_repo" --path "$clone_tester_repo"
        
        cd $local_tester_repo
        
        git artifact add-as-submodule --url "../$remote_tester_repo" --path submodule-repo
        
        git status 

        git commit -m "Added submodule repo"
        git push origin HEAD:"${default_branch:-main}"
        git fetch origin -apP

        generate_git_test_log
        cat .gitmodules >> ${root_folder}/${test}/git-test.log
        git status >> ${root_folder}/${test}/git-test.log
        
    } > ${root_folder}/${test}/run.log 2>&1 || { pwd && cat ${root_folder}/${test}/run.log; }
    eval_testcase
}


if [[ ${arg_testcase:-} == "" ]]; then 
    # Dynamically list and call test functions
    mapfile -t test_functions < <(declare -F | awk '{print $3}' | grep -E '^[0-9]+(\.[0-9]+)?$')

    for fn in "${test_functions[@]}"; do
        "$fn" || {
            echo "Test case '$fn' failed. Check the logs in .test/$fn/run.log"
            global_exit_code=1
        }
    done
else
    # Run a specific test case if provided
    if declare -F "$arg_testcase" > /dev/null; then
        "$arg_testcase"
    else
        echo "Test case '$arg_testcase' not found."
        exit 1
    fi
fi


echo
echo "########################################"
echo "All tests completed. Checking results..."
echo "########################################"
echo

if [[ ${global_exit_code:-0} -eq 0 ]]; then 
    echo "All tests passed successfully."
else
    echo
    echo "Contents of failed test logs:"
    echo "-----------------------------"
    for log in $( find . -name run.log -o -name nok.log | sort ); do
        echo
        echo "--- $log start ------------------------"
        cat "$log"
        echo "--- $log end ------------------------"
        echo
    done
    echo
    echo "Some tests failed. - List of logs:"
    find . -name run.log -o -name nok.log | sort
    echo
fi  
# Exit with the global exit code
exit $global_exit_code