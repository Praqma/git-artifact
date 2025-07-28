# git-artifact 🚀📦

> Effortless artifact management using Git repositories

## Why use `git-artifact`?

`git-artifact` brings artifact management directly into your Git workflow, making it easy to store, version, and retrieve build artifacts without extra infrastructure.

### Super simple

To push artifacts:

- `git artifact init` to set up a new repository for artifact management.
- Add files (e.g., binaries, libraries) directly to the repository without zipping or archiving.
- Use `git artifact add-n-push` to commit and push artifacts with a tag, like `v1.0`, ensuring they are versioned and easily retrievable.

To retrieve artifacts:

- `git artifact clone` to clone the repository.
- Use `git artifact find-latest -r 'v*.*'` to search for the latest version of an artifact.
- Use `git artifact fetch-co-latest --regex 'v*.*'` to download and checkout the latest artifact version, files are ready to use!

No external tools or complex configurations are needed. `git-artifact` leverages Git's powerful version control features to manage artifacts as if they were part of your source code.

### Key Benefits

- **Seamless integration:** Manage artifacts alongside your source code using familiar Git tools.
- **Efficient storage:** Artifacts are stored as independent commits, so you fetch only what you need.
- **Traceability & integrity:** Tags and Git’s checksums provide clear versioning and authenticity.
- **Easy cleanup:** Remove intermediate artifacts by simply deleting their tags.
- **Unified workflow:** Eliminate the need for separate artifact repositories or complex tools.

Whether for embedded, enterprise, or CI/CD environments, `git-artifact` streamlines artifact management by making it a natural extension of your existing Git processes.

## How to use `git-artifact`

### Install git-artifact

To install `git-artifact`, simply download or clone this repository and ensure the script is available in your `PATH`. Once in your `PATH`, `git` will automatically recognize `git-artifact` as a native subcommand (`git artifact`), seamlessly extending your Git functionality.

Or quickly install `git-artifact` by running:

```bash
mkdir -p ~/.local/bin && curl -o ~/.local/bin/git-artifact https://raw.githubusercontent.com/praqma/git-artifact/main/git-artifact && chmod +x ~/.local/bin/git-artifact
```

Make sure `~/.local/bin` is included in your `PATH` environment variable:

```bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc && source ~/.bashrc
```

Now you can use `git artifact` as a regular Git command.

### Create a test repository

- Create a repo, for example on GitHub: [https://github.com/new?name=test-git-artifact]

- Use the `git artifact init` command to initialize a new repository locally for managing artifacts.

```bash
# replace `__USERNAME__` with your GitHub username
git artifact init --url=git@github.com:__USERNAME__/test-git-artifact.git --path test-git-artifact
```

### Add the artifact

Copy the artifacts to your path in the folder structure the "consumer" desire it. There is not reason to tar or zip it. Git will handling this for optimized storage and easiness.

```bash
cd test-git-artifact
touch artifact-1.0
# cp -rf <build-dir>/my.lib /include .
git artifact add-n-push -t v1.0
```

Voila! The artifact v1.0 is now commited, pushed _and_ importantly - the workspace is set back to the default branch of the remote repository. It is now ready to make a new artifact based on the default branched

### Finding and getting artifacts

```bash
# You can use the `git artifact clone` command to clone a repository and set it up for artifact management. Note that you only clone and get the default branch!
git artifact clone --url=git@github.com:__USERNAME__/test-git-artifact.git --path test-git-artifact
cd test-git-artifact
```

```bash
# Find the latest using pattern
git artifact find-latest -r 'v*.*'
```

```bash
# Download and checkout the latest
git artifact fetch-co-latest --regex 'v*.*'
```

## Advanced

### Appending to an artifact

You can append to an artifact with advantage. Let say you create a library and you run a lot of tests in a later stage and the result is a test report. You can then just add that on top of the library tag.  

- Download and checkout the artifact ( see above )
- Add a new artifact ( see above )

You should of course consider this in your naming convension. Consider something like this:

```bash
vX.Y.Z/release-note
vX.Y.Z/test
vX.Y.Z/src
vX.Y.Z/lib
```

#### Add the source code that was used to build the artifact

The source code in many companies and open-source projects are free to view, debug and edit. You can make it easy accessable by adding the source code as submodule and sha1 in to the artifact history. It sounds odd, but it gives the developers easy access to checkout the correct version that was used to build artifact.

This way it actually possible to create a full block-chain of everything that was involved in producing a product.

### LFS

`git artifact` work great out of the box without any extensions like LFS. It can though still be interesting to commit an `git-lfs` configuration to the default branch

- Artifact sets that can many common binary/large files from version to version will then be able to detect that it already have have this file in the LFS storage and do not have to fetch/push it again.
- You can download all tags without checkout and then you can search for meta-data in the annotated tags without suffering large data transfer and storage in order to clean.

### Promotions

There are genrally default two ways to you can do promotions.
Building new artifacts for the release is like a new artifact using the above patterns, which can either be a new or appended artifacts.

Promotion decision should also be seen in connection related to pruning of tag which is not valid of any interest anymore. It should be simple and easy to prune without fear of deleting tags that should not be deleted

#### Using different repository

This way is like promotion in normal artifact managemnet systems, where you promote to from one project/repository to another. You basically download the tag from the original repository and then push the tag to promotion reposity. This way you can control access and keep different URL's for candidates and releases.

#### Using same repository

This way requires you to create a tag using a release tag pattern. The tag can either be a new unrelated tag or it can be append on top if a release candidate tag.

### Add information to the annotated tag

TODO: option for file or string

### Pruning / cleaning artifacts

TODO: based on count..

## Notes

### Permissions needed

`git-artifact` relies on Git tags for artifact management. As a producer, you need permission to create and push tags to the remote repository. To effectively manage and clean up old artifacts, having permission to delete tags is also recommended.

Alternatively, `git-artifact` can operate in branch mode, maintaining a `latest` branch to track the most recent artifact. This requires force-push or delete-and-push rights for the branch. The approach is similar to Docker’s `<image>:latest` tag and is useful if you want to use tracking branches outside of `git-artifact`—for example, with Git submodules or repo manifests.

### Producer of artifacts

A few remarks, aspects and thoughts when storing the artifacts

- easy to append artifacts as stages evolves with more artifacts
- no need to zip before upload - just commit as the artifact should be used.
- easy to add information, environment, tools and git source sha1 in the artifact for traceability and later reproduction
- add the source code as a dependency to the artifact. It will then be easy restore the source for diff and debugging

### Consumer of the artifacts

A few remarks, aspects and thoughts when retrieving the artifacts

- The consumer do not need anything than standard git
- Pipelines just consumes the artifact unzip and ready to use as they were produced
- Use your favorit git dependency system like submodules(this is the correct way for submodule usage btw ), repo tool or ..
- Even a consumer can be a producer by adding further artifacts on top the consumed commit with a new commit and tag
- git understand the content in workspace and git clean does not remove artifacts in contrast to downloaded artifacts

### How is it done

Git normally stacks the history hence you cannot delete commit in the middle of the history. `git-artifact` make a "horizontal" history - i.e the commits are not stacked on top of each other, but next to each other.

The history of git-artifact workflow can basically look like this:

``` mermaid
%%{init: { 
    'gitGraph': {
        'loglevel' : 'debug',
        'orientation': 'vertical', 
        'showCommitLabel': true, 
        'showBranches': false
    }} }%%
gitGraph:
   commit id: "init" tag: "init" type:  HIGHLIGHT
   branch latest-1.0 order: 2
   branch latest-1.1 order: 3
   branch latest-1.2 order: 4
   branch latest-2.0 order: 5
   checkout latest-1.0
   commit id: "1.0/bin" tag: "1.0/bin"
   commit id: "1.0/src" tag: "1.0/src"
   checkout latest-1.1
   commit id: "1.1/bin" tag: "1.1/bin"
   checkout latest-1.2
   commit id: "1.2/bin" tag: "1.2/bin"
   checkout latest-2.0
   commit id: "2.0/bin" tag: "2.0/bin"
   checkout main
   commit id: "update scripts" tag: "main" type:  HIGHLIGHT
   branch foo order: 1
   checkout foo
   commit id: "3.0/bin" tag: "3.0/bin"
   checkout latest-2.0
   commit id: "2.0/src" tag: "2.0/src"
   commit id: "2.0/test" tag: "2.0/test"
```
