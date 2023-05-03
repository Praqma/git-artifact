# git-artifact

## Why

### Overall
- no new tools involved ( artifact management system )
- Same credentials scheme as your source code ( even ssh )
- easy to trigger in pipelines based on tags or branch updates
- no need for release drives/shares which lack features for tracing and maintenance
- Git's normal garbage collection takes care of the details for cleaning

### Producer
- Add the git-artifact repo as submodule. Let the make system output to the git-artifact repo directory ready to commit
- easy to append artifacts as stages evolves with more artifacts
- no need to zip before upload nor unzip after download
- easy to add information, environment, tools and git source sha1 in the artifact for traceability and later reproduction

### Consumer
- easy to use a submodule for other repo as a dependency
- even a consumer can be a producer adding further artifacts on top the consumed commit with a new commit and tag
- git understand the content in workspace and git clean does not remove artifacts in contrast to zip'ed artifacts

## The concept
Git normally stacks the history hence you cannot delete commit in the middle of the history. `git-artifact` make a "horizontal" history - i.e the commits are not stacked on top of each other, but next to each other. The only stacked commit are only when you append to an artifact and give it additional tag name stated the new layer of artifacts.

The history is basically like this 
```
          [0.2/test] 
             |
[0.1/bin] [0.2/bin]  [0.3/bin]
|           /          / 
<main>
```

### Prerequisites 
The tool uses tags hence the user need to tags push rights. It is also beneficial to have delete tag rights to clean old artifacts. It can also run in branch mode so it for example maintains a `latest` branch which needs force push / delete rights. The concept is similar to docker concept of `<image>/latest` 

### Advises

## Initialize
TODO:

## Searching
TODO:

### git ls-remote
```
git ls-remote origin --tags | grep <pattern>
```
  
### git log
```
git log --grep <pattern>
```

## Pruning / cleaning artifacts
### using `git log` and get tags with a certain pattern 
### 

## Advanced

### Cloning with filter
- only some repo managers can do this

### LFS

### Dual artifactory and git-artifact usages
- set your LFS store to be Artifactory and then can normal artifacts via upload and LFS have traceability
