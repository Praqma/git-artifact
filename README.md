# git-artifact

## The rational for storing artifacts in git
I have, over the years in the embbeded enterprise industry, constantly come across many scenarios where zipping, downloading and unzipping generic dependencies and maintaining workspace
has slowed down turn around time for developers and CI system. Git is a fantastic zipper it self and you get integrity of workspaces for free.

Git has always been mentioned to be bad for storing artifacts due to the block chain technology and distrubuted architecture. Git-artifact make sure this problem is handled by storing commits "horisontally" using tags rather than the default "stacked" way. It gives a few advantages compared to standard usage of git: 
- Firstly; You can garbage collect intermidiate artifacts by just deleting the tag
- Secondly; You only fetch what you need - even without using shallow. 

### CI/CD integration
Triggering of new builds or tests are done the normal way as known from triggering your pipelines of source code - push or pull - simple..

### Save money
You can save additional license and maintainance cost and/or coqnative load by maintaining and using an additional system for artifacts. You can handle it with your current git repository manager.

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

## How is it done
Git normally stacks the history hence you cannot delete commit in the middle of the history. `git-artifact` make a "horizontal" history - i.e the commits are not stacked on top of each other, but next to each other.

The history is basically like this 

``` mermaid
%%{init: { 'gitGraph': {'showCommitLabel': false, 'showBranches': false}} }%%
gitGraph
   commit id: "init" tag: "init"
   branch latest-1.0
   branch latest-1.1
   branch latest-1.2
   branch latest-2.0
   branch latest
   checkout latest-1.0
   commit id: "1.0/bin" tag: "1.0/bin"
   commit id: "1.0/src" tag: "1.0/src"
   checkout latest-1.1
   commit id: "1.1/bin" tag: "1.1"
   checkout latest-1.2
   commit id: "1.2/bin" tag: "1.2"
   checkout latest-2.0
   commit id: "2.0/bin" tag: "2.0"
   checkout latest-1.0
   commit id: "2.0/test" tag: "2.0/test"
``` 
  
``` mermaid
graph TD;
    0.1/bin --> main;
    0.2/test --> 0.2/src --> 0.2/bin --> main;
    0.2/bin --> main;
    0.3/bin --> main;
```

`git-artifacts` has all the functions available that make the above history straight for and natural workflow. 

### Prerequisites 
The tool uses tags hence the producer need to tag push-rights. It is also beneficial to have tag delete-rights to clean old artifacts. 

It can also run in branch mode. It can  maintain a `latest` branch which needs to be force pushed or delete + push rights. The concept is similar to docker concept of `<image>/latest`. It is only important if you want to use tracking branches without using `git-artifact`. It could be in context of `submodules` or `repo manifests`.

### Installation
Download or clone this repo (`git-artifact`) and add make it available in the PATH. Given that `git-artifact` is in the PATH, then `git` can use it as an command like `git artifact`. It is now integrated with git and git is extended.

## Getting started
First you need to create a repository in your git repository manager. You can either choose to initialize the repo, but `git artifact` also have command to do that and it states that this repository is "special" repository containing git artifacts.

### Initialize the repository
Let us now initialized a repo:
```
git artifact init --url=<remote_url> --path my-git-artifact-path
```

### Add the artifact
The repository and path initialize above ready to use. Copy the artifacts to your path in the folder structure the "constumer" desire it. There is not reason to tar or zip it. Git will handling this for optimized storage and easiness.

```
cd my-git-artifact-path
cp -rf <build-dir>/my.lib /include .
git artifact add-n-push -t v1.0
```
The artifact v1.0 is now commited, pushed _and_ importantly - the workspace is set back to the default branch of the remote repository. It is now ready to make a new artifact based on the default branched

## Finding and getting artifacts
Firstly clone the git artifact repository. Note that you only clone and get the default branch
```
git artifact clone --url=<remote> --path my-git-artifact-path
cd my-git-artifact-path
````

### Find the latest using pattern
```
git artifact find-latest -r 'v*.*'
```
### Download and checkout the latest
```
git artifact fetch-co-latest --regex 'v*.*'
```

## Appending to an artifact
You can append to an artifact with advantage. Let say you create a library and you run a lot of tests in a later stage and the result is a test report. You can then just add that on top of the library tag.  

- Download and checkout the artifact ( see above )
- Add a new artifact ( see above )

You should of course consider this in your naming convension. Consider something like this:
```
vX.Y.Z/release-note
vX.Y.Z/test
vX.Y.Z/src
vX.Y.Z/lib
```

### Add the source code that was used to build the artifact
The source code in many companies and open-source projects are free to view, debug and edit. You can make it easy accessable by adding the source code as submodule and sha1 in to the artifact history. It sounds odd, but it gives the developers easy access to checkout the correct version that was used to build artifact.

This way it actually possible to create a full block-chain of everything that was involved in producing a product.

## Add information to the annotated tag
TODO: option for file or string

## Pruning / cleaning artifacts
TODO: based on count.. 



## Advanced

### LFS
`git artifact` work great out of the box without any extensions like LFS. It can though still be interesting to commit an `git-lfs` configuration to the default branch. 
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


