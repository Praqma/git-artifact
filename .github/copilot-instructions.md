# git-artifact Repository Instructions

Always follow these instructions first and only fallback to additional search and context gathering if the information here is incomplete or found to be in error.

## Overview

git-artifact is a Bash-based CLI tool that uses git repositories as artifact management storage. It creates "horizontal" git history using tags rather than stacked commits, allowing efficient artifact storage and retrieval without the typical drawbacks of storing large files in git.

## Environment Requirements

- Bash 4.3 or higher (the tool validates this automatically)
- Git (any modern version - tested with 2.26.2 through latest)
- No compilation or build process required - it's a pure Bash script

## Installation and Setup

Add the git-artifact script to your PATH:
```bash
export PATH=/home/runner/work/git-artifact/git-artifact:$PATH
```

The tool then becomes available as a git subcommand:
```bash
git artifact -h
```

## Testing and Validation

### Full Test Suite
Run all tests - NEVER CANCEL, takes approximately 60 seconds:
```bash
# Set required git configuration first
git config --global user.email "test@example.com"
git config --global user.name "Test User"

# Run complete test suite - NEVER CANCEL: takes 60+ seconds
timeout 180s bash _tests.sh
```

### Individual Test Cases
Run specific test cases for faster iteration (takes 7-15 seconds each):
```bash
# Run single test case for faster validation
bash _tests.sh -t 1      # Basic repo test
bash _tests.sh -t 5      # Complex fetch-co-latest test (~7 seconds)
bash _tests.sh -t 9      # Prune functionality test
```

### Manual Functional Validation
Always test core functionality after making changes:
```bash
# Create test environment
mkdir -p /tmp/validation-test && cd /tmp/validation-test

# Initialize artifact repository (takes <1 second)
git init --bare test-remote
git -C test-remote symbolic-ref HEAD refs/heads/main  # Required for proper setup
git artifact init --url="$(pwd)/test-remote" --path test-repo

# Add an artifact (takes <1 second)
cd test-repo
echo "validation content" > test-artifact.txt
git artifact add-n-push -t v1.0

# Clone and fetch artifact (takes <1 second each)
cd ..
git artifact clone --url="$(pwd)/test-remote" --path test-consumer
cd test-consumer
git artifact fetch-co -t v1.0

# Verify artifact content
cat test-artifact.txt  # Should show "validation content"
```

## Linting and Code Quality

Run shellcheck linting - takes approximately 2 seconds:
```bash
# NEVER CANCEL: shellcheck analysis takes ~2 seconds
timeout 30s shellcheck git-artifact _tests.sh
```

Note: shellcheck will show many SC2086 warnings (quoting recommendations) but these are informational and do not break functionality.

## Key Commands and Timing

### Core Operations (all complete in <1 second)
- `git artifact init --url=<remote> --path <path>` - Initialize new artifact repo
- `git artifact clone --url=<remote> --path <path>` - Clone existing artifact repo  
- `git artifact add-n-push -t <tag>` - Add and push artifacts
- `git artifact fetch-co -t <tag>` - Fetch and checkout specific artifact
- `git artifact list -g '<pattern>'` - List artifacts matching pattern

### Management Operations
- `git artifact find-latest -g '<pattern>'` - Find latest artifact
- `git artifact prune --glob '<pattern>' --keep <count>` - Clean old artifacts
- `git artifact summary` - Show artifact statistics

## Docker Testing (Optional)

The repository includes Docker-based testing for multiple Git versions. NEVER CANCEL these builds - they can take 2-5 minutes:
```bash
# Build test container - NEVER CANCEL: takes 2-5 minutes
# Note: May fail due to network/permission issues with Alpine package repositories
timeout 600s docker build --build-arg ALPINE_GIT_DOCKER_VERSION="latest" \
    --build-arg USER_ID="$(id -u)" --build-arg GROUP_ID="$(id -g)" \
    -t "git-artifact:latest" .

# Run containerized tests - NEVER CANCEL: takes 60+ seconds
timeout 180s docker run --rm -v "$(pwd):/git" "git-artifact:latest" artifact-tests
```

Note: Docker builds may occasionally fail due to Alpine Linux package repository access issues. This does not affect core functionality since git-artifact is a pure Bash script.

## Common Workflows

### Adding New Functionality
1. Make code changes to `git-artifact` script
2. Run shellcheck: `shellcheck git-artifact` (~2 seconds)
3. Run relevant test: `bash _tests.sh -t <testnum>` (~7 seconds)
4. Run full test suite: `bash _tests.sh` (~60 seconds) - NEVER CANCEL
5. Manually validate with functional test scenario above

### Adding New Tests
1. Create new test directory: `mkdir .test/<number>`
2. Add test function to `_tests.sh` following existing patterns
3. Create `git-reference.log` with expected output
4. Test with: `bash _tests.sh -t <number>`

### Debugging Test Failures
- Check `.test/<testnum>/run.log` for execution details
- Check `.test/<testnum>/nok.log` for failure details
- Run single test with debug: `bash _tests.sh -t <testnum> --debug`

## Repository Structure

```
/home/runner/work/git-artifact/git-artifact/
├── git-artifact           # Main executable (700+ lines of Bash)
├── _tests.sh              # Test runner (480+ lines)
├── README.md              # Comprehensive documentation
├── Dockerfile             # For multi-version Git testing
├── .github/workflows/     # CI pipeline
├── .test/                 # Test scenarios (1, 1.1, 2, 3, etc.)
└── .gitignore            # Excludes test artifacts
```

## Validation Requirements

After ANY changes, always run this complete validation sequence:
1. Shellcheck linting (2 seconds): `shellcheck git-artifact _tests.sh`
2. Single test validation (7 seconds): `bash _tests.sh -t 1` 
3. Manual functional test (30 seconds): Follow "Manual Functional Validation" above
4. Full test suite (60 seconds): `bash _tests.sh` - NEVER CANCEL

## CI/CD Integration

The `.github/workflows/pr.yml` runs tests against multiple Git versions:
- Native Ubuntu git
- Alpine git latest, v2.49.0, v2.47.2, v2.36.2, v2.26.2

All CI tests must pass. The workflow takes several minutes due to Docker builds but validates compatibility across Git versions.

## Important Notes

- NEVER CANCEL long-running commands - builds and tests may take several minutes
- The tool requires git remote repositories to have proper HEAD references set
- All operations work with both local and remote git repositories
- The tool handles both annotated and lightweight tags
- Branch operations support force-push scenarios for artifact updates