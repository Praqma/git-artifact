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

## Prerequisites 
We are using the full freedom and powers of Git, so it is required to have delete/force push permissions to branches in order move branch heads to new artifacts that is not fast forwards.

### Advises
Define a tag- and branch-name strategy for each "layer" of git-artifacts. This simplifies appending to old artifacts and allows keeping several artifacts in the same repository. With only one artifact, the scheme could be `unsigned/latest` and `signed/latest` for branches. Tags could use `1.1.8928/unsigned`, `1.1.8928/signed`, `1.1.8928/targettest-passed`, `1.1.8928/targettest-failed`, `1.1.8928/regression-passed` etc. Adding an artifact name would allow more than one artifact in the repository.

## Initialize
```
git init
touch .gitignore && git add .gitignore
touch .gitattributes && git add .gitattributes
git commit -m "Initialize the git artifact repository"
git remote add origin <artifact-url>
git push origin master/main
```

## Adding a new artifact to the artifact-repo
```
git clone -b master -depth 1 <artifact-url>
:git add $file: || git add .
git commit -m "$message"
git tag -a -m "$message" $tag
git push origin $tag:refs/tags/$tag
git push origin latest --force
```
  
## Consume the latest git-artifact
```
git clone -b latest -depth 1 <repo-url>
```

## Appending to latest artifact
```
git clone -b latest -depth 1 <repo-url>
:repeat: git add $file || git add .
git commit -m "$append_message"
git tag -a -m "$append_message" $append_tag
git push origin $append_tag:refs/tags/$append_tag
git push origin latest_append --force
```
  
## Searching

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
