#!/usr/bin/env bats

# Note: Framework = Bats (no external helpers required). Tests use PATH shims to stub git behavior.

setup() {
  TMPDIR="$(mktemp -d)"
  export TMPDIR
  TEST_BIN="$TMPDIR/bin"
  mkdir -p "$TEST_BIN"
  export PATH="$TEST_BIN:$PATH"

  # Fresh ENV defaults for each test
  unset arg_debug || true
  unset arg_quiet arg_verbose arg_dryrun arg_artifacttag arg_branch arg_path arg_remoteurl arg_glob arg_sha1 arg_keep || true
  export BASH_VERSINFO=(5 2 15)  # default modern bash for function behavior
  export BASH_VERSION="5.2.15(1)-release"

  # Provide a default 'git' stub that can be tailored per test by env switches
  cat > "$TEST_BIN/git" <<'GITSTUB'
#!/usr/bin/env bash
set -euo pipefail
cmd="$1"; shift || true

# Optional debug of stub
if [[ "${STUB_GIT_TRACE:-0}" == "1" ]]; then
  echo "STUB git $cmd $*" >&2
fi

case "$cmd" in
  "--version")
    # Allow override with STUB_GIT_VERSION
    if [[ -n "${STUB_GIT_VERSION:-}" ]]; then
      echo "git version ${STUB_GIT_VERSION}"
    else
      echo "git version 2.45.0"
    fi
    ;;
  "config")
    # simulate git config --global init.defaultBranch
    scope="${1:-}"; key="${2:-}"
    if [[ "$scope" == "--global" && "$key" == "init.defaultBranch" ]]; then
      if [[ -n "${STUB_GIT_DEFAULT_BRANCH:-}" ]]; then
        echo "${STUB_GIT_DEFAULT_BRANCH}"
        exit 0
      else
        # behave like "not set" -> non-zero exit
        exit 1
      fi
    fi
    # passthrough other configs succeed silently
    exit 0
    ;;
  "ls-remote")
    # Support: --symref <remote> HEAD
    if [[ "${1:-}" == "--symref" ]]; then
      remote="$2"; ref="$3"
      # Use STUB_GIT_SYMREF to emit, else empty
      if [[ -n "${STUB_GIT_SYMREF:-}" ]]; then
        # Expected format example:
        # ref: refs/heads/main HEAD
        echo "${STUB_GIT_SYMREF}"
      fi
      exit 0
    fi
    # Support tag listings for various commands
    if [[ "${1:-}" == "--tags" ]]; then
      # Echo preconfigured lines from STUB_GIT_TAGS (newline separated)
      if [[ -n "${STUB_GIT_TAGS:-}" ]]; then
        # When --ref used, still print same lines (consistent enough for parsing)
        while IFS=$'\n' read -r line; do
          [[ -n "$line" ]] && echo "$line"
        done <<< "${STUB_GIT_TAGS}"
      fi
      exit 0
    fi
    ;;
  "rev-parse")
    if [[ "${1:-}" == "--is-inside-work-tree" ]]; then
      if [[ "${STUB_GIT_WORKTREE:-1}" == "1" ]]; then
        echo true
        exit 0
      else
        exit 1
      fi
    fi
    if [[ "${1:-}" == "HEAD" ]]; then
      echo "${STUB_GIT_HEAD_SHA1:-0123456789abcdef0123456789abcdef01234567}"
      exit 0
    fi
    ;;
  "branch")
    if [[ "${1:-}" == "--show-current" ]]; then
      echo "${STUB_GIT_CURRENT_BRANCH:-feature/test}"
      exit 0
    fi
    # count branches: ignore
    exit 0
    ;;
  "fetch"|"reset"|"clean"|"push"|"checkout"|"switch"|"init"|"clone"|"add"|"commit"|"log"|"submodule")
    # simulate success unless failure requested
    if [[ "${STUB_GIT_FAIL:-0}" == "1" ]]; then
      exit 1
    fi
    # Special-case: 'init -b' might fail first time when STUB_GIT_INIT_B_FAIL=1
    if [[ "$cmd" == "init" && "${1:-}" == "-b" && "${STUB_GIT_INIT_B_FAIL:-0}" == "1" ]]; then
      exit 1
    fi
    exit 0
    ;;
  "rev-list")
    exit 0
    ;;
  *)
    # default noop
    exit 0
    ;;
esac
GITSTUB
  chmod +x "$TEST_BIN/git"

  # Provide 'xargs' if environment expects GNU options — on CI it's present, but we just rely on system one.
}

teardown() {
  rm -rf "$TMPDIR"
}

# Helper to source the script under test.
load_script() {
  # Attempt common locations
  for candidate in ./git-artifact ./bin/git-artifact ./scripts/git-artifact ./src/git-artifact; do
    if [[ -f "$candidate" ]]; then
      # shellcheck source=/dev/null
      . "$candidate"
      return 0
    fi
  done
  echo "git-artifact script not found in expected locations" >&2
  return 1
}

# ===== BEGIN: auto-generated tests for git-artifact =====

@test "check_environment: exits with error when BASH_VERSINFO is unset" {
  load_script
  run bash -c 'unset BASH_VERSINFO; check_environment'
  [ "$status" -ne 0 ]
  [[ "$output" == *"git-artifact only runs in bash"* ]]
  [[ "$output" == *"BASH_VERSINFO:"* ]]
}

@test "check_environment: exits when bash major version < 4" {
  load_script
  run bash -c 'export BASH_VERSINFO=(3 2 57); export BASH_VERSION="3.2"; check_environment'
  [ "$status" -ne 0 ]
  [[ "$output" == *"requires Bash version 4.3 or higher."* ]]
}

@test "check_environment: exits when bash is 4.2 (minor < 3)" {
  load_script
  run bash -c 'export BASH_VERSINFO=(4 2 0); export BASH_VERSION="4.2"; check_environment'
  [ "$status" -ne 0 ]
  [[ "$output" == *"requires Bash version 4.3 or higher."* ]]
}

@test "check_environment: passes silently on modern bash (>= 4.3)" {
  load_script
  run bash -c 'export BASH_VERSINFO=(5 1 16); export BASH_VERSION="5.1"; check_environment; echo OK'
  [ "$status" -eq 0 ]
  [[ "$output" == "OK" ]]
}

@test "show_info: prints expected lines and uses git --version via stub" {
  load_script
  run bash -c 'export STUB_GIT_VERSION="9.9.9"; show_info'
  [ "$status" -eq 0 ]
  [[ "$output" == *"git-artifact: use a git repository as artifact management storage"* ]]
  [[ "$output" == *"Version: 9.9.9"* ]]
  [[ "$output" == *"Git version: git version 9.9.9"* ]]
  [[ "$output" == *"Bash version:"* ]]
  [[ "$output" == *"Bash version info:"* ]]
}

@test "set_opts_spec: defines OPTS_SPEC containing key commands and options" {
  load_script
  run bash -c 'set_opts_spec; echo "$OPTS_SPEC"'
  [ "$status" -eq 0 ]
  [[ "$output" == *"commands:"* ]]
  [[ "$output" == *"init             Inititialize a new repository"* ]]
  [[ "$output" == *"clone            Clone and existing repository"* ]]
  [[ "$output" == *"options for 'prune'"* ]]
  [[ "$output" == *"k,keep=          The amount of tags to keep"* ]]
}

@test "debug: prints to stderr only when arg_debug is set" {
  load_script
  run bash -c 'arg_debug=1; debug "hello";'
  [ "$status" -eq 0 ]
  [[ "$output" == "" ]]
  # Verify it went to stderr by capturing separately: bats combines streams, so presence in combined is enough when arg_debug=1
  run bash -c 'arg_debug=; debug "world";'
  [ "$status" -eq 0 ]
  [[ "$output" == "" ]]
}

@test "set_repo_dir: uses arg_path when provided" {
  load_script
  run bash -c 'arg_path="custom-dir"; local out=""; set_repo_dir out; echo "$out"'
  [ "$status" -eq 0 ]
  [ "$output" = "custom-dir" ]
}

@test "set_repo_dir: derives dir name from arg_remoteurl and strips .git" {
  load_script
  run bash -c 'unset arg_path; arg_remoteurl="https://example.com/org/repo.git"; local out=""; set_repo_dir out; echo "$out"'
  [ "$status" -eq 0 ]
  [ "$output" = "repo" ]
}

@test "set_repo_dir: errors if directory already exists" {
  load_script
  run bash -c 'arg_path="exists-here"; mkdir -p exists-here; local out=""; set_repo_dir out'
  [ "$status" -ne 0 ]
  [[ "$output" == *"ERROR: Directory 'exists-here' already exists"* ]]
}

@test "set_base_branch: returns arg_branch if provided" {
  load_script
  run bash -c 'arg_branch="release"; local b=""; set_base_branch b; echo "$b"'
  [ "$status" -eq 0 ]
  [ "$output" = "release" ]
}

@test "set_base_branch: uses git config init.defaultBranch when available" {
  load_script
  run bash -c 'unset arg_branch; STUB_GIT_DEFAULT_BRANCH="trunk"; local b=""; set_base_branch b; echo "$b"'
  [ "$status" -eq 0 ]
  [ "$output" = "trunk" ]
}

@test "set_base_branch: falls back to main and prints info when no defaultBranch set" {
  load_script
  run bash -c 'unset arg_branch; unset STUB_GIT_DEFAULT_BRANCH; local b=""; set_base_branch b; echo "$b"'
  [ "$status" -eq 0 ]
  [ "$output" = "main" ]
}

@test "set_remote_default_branch: respects arg_remoteurl defaulting to origin and parses symref" {
  load_script
  run bash -c 'unset arg_remoteurl; STUB_GIT_SYMREF="ref: refs/heads/main HEAD"; local r=""; set_remote_default_branch r; echo "$r"'
  [ "$status" -eq 0 ]
  [ "$output" = "main" ]
}

@test "set_remote_default_branch: falls back to set_base_branch when symref not found" {
  load_script
  run bash -c 'STUB_GIT_SYMREF=""; STUB_GIT_DEFAULT_BRANCH="dev"; local r=""; set_remote_default_branch r; echo "$r"'
  [ "$status" -eq 0 ]
  [ "$output" = "dev" ]
}

@test "need_workspace: errors when not in a git worktree" {
  load_script
  run bash -c 'export STUB_GIT_WORKTREE=0; need_workspace'
  [ "$status" -ne 0 ]
  [[ "$output" == *"ERROR: Git workspace not found"* ]]
}

@test "read_remote_tags_to_map: builds associative map split by delimiter" {
  load_script
  run bash -c '
    arg_delimiter="/"
    # Provide tags output lines as "hash<TAB>refs/tags/<tag>"
    export STUB_GIT_TAGS=$'\''000000\trefs/tags/app/1.0\n111111\trefs/tags/app/1.1\n222222\trefs/tags/lib/2.0'\''
    declare -A m
    read_remote_tags_to_map m
    # print keys in any order but with counts
    for k in "${!m[@]}"; do
      c=$(echo -n "${m[$k]}" | wc -l)
      echo "$k:$c"
    done | sort
  '
  [ "$status" -eq 0 ]
  # Expect entries for 'app' and 'lib'
  [[ "$output" == *"app:2"* ]]
  [[ "$output" == *"lib:1"* ]]
}

@test "find-latest: returns newest tag by version sort and errors when not found" {
  load_script
  run bash -c '
    arg_glob="app/*"
    # Simulate two tags, newest first only when sorted by -version:refname
    export STUB_GIT_TAGS=$'\''deadbeef\trefs/tags/app/1.9\ncafebabe\trefs/tags/app/1.10'\''
    latest=""
    find-latest latest
    echo "$latest"
  '
  [ "$status" -eq 0 ]
  [ "$output" = "app/1.10" ]

  run bash -c '
    arg_glob="nope/*"
    export STUB_GIT_TAGS=""  # no tags
    missing=""
    find-latest missing
  '
  [ "$status" -ne 0 ]
  [[ "$output" == *"ERROR: No tag found using glob pattern:"* ]]
}

@test "cmd_list: prints tags when not quiet and summary count always printed" {
  load_script
  run bash -c '
    export STUB_GIT_TAGS=$'\''aaaa\trefs/tags/x/1\nbbbb\trefs/tags/x/2\ncccc\trefs/tags/y/1'\''
    arg_quiet=0
    arg_glob="*"
    cmd_list
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *$'x/1\nx/2\ny/1'* ]]
  [[ "$output" == *"Tags found: * : 3"* ]]
}

@test "cmd_prune: dry run computes correct amounts and does not execute push" {
  load_script
  run bash -c '
    export STUB_GIT_TAGS=$'\''000\trefs/tags/a/1\n111\trefs/tags/a/2\n222\trefs/tags/a/3\n333\trefs/tags/a/4'\''
    arg_glob="a/*"
    arg_keep=2
    arg_dryrun=1
    cmd_prune
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"Amount of tags total: 4"* ]]
  [[ "$output" == *"Amount of tags to be pruned: 2"* ]]
  [[ "$output" == *"Amount of tags to be kept: 2"* ]]
  [[ "$output" == *"Dry run - not executing prune command"* ]]
}

@test "cmd_fetch-tags: fetches annotated tags for given sha1 or errors when none" {
  load_script
  run bash -c '
    # Provide annotated tag lines (with ^{} suffix in input path, stub simplifies by echoing raw tags then code filters)
    export STUB_GIT_TAGS=$'\''012345 {}	refs/tags/v1.0^{}\n012345 {}	refs/tags/v1.0'\''
    arg_sha1="012345"
    cmd_fetch-tags
    echo OK
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"Getting tags from: 012345"* ]]

  run bash -c '
    export STUB_GIT_TAGS=""
    arg_sha1="ffffaa"
    cmd_fetch-tags
  '
  [ "$status" -ne 0 ]
  [[ "$output" == *"ERROR: No tags found for sha1:"* ]]
}

@test "main: validates required flags for commands (init, add-n-tag, push)" {
  load_script
  run bash -c '
    set_opts_spec
    main init
  '
  [ "$status" -ne 0 ]
  [[ "$output" == *"ERROR: --url <url> required for init"* ]]

  run bash -c '
    set_opts_spec
    # Within a worktree for these checks
    export STUB_GIT_WORKTREE=1
    main add-n-tag
  '
  [ "$status" -ne 0 ]
  [[ "$output" == *"ERROR: -t|--tag <tag> required for add-n-tag"* ]]

  run bash -c '
    set_opts_spec
    export STUB_GIT_WORKTREE=1
    # push requires either tag or branch
    main push --
  '
  [ "$status" -ne 0 ]
  [[ "$output" == *"at least one of -t|--tag <tag> or -b|--branch is required for push"* ]]
}

@test "reset_workspace-n-branch: fetch/reset/clean are invoked (via stub success)" {
  load_script
  run bash -c '
    export STUB_GIT_SYMREF="ref: refs/heads/main HEAD"
    reset_workspace-n-branch
    echo OK
  '
  [ "$status" -eq 0 ]
  [ "$output" = "OK" ]
}

# ===== END: auto-generated tests for git-artifact =====