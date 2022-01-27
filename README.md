# git-artifact

## Why

### Overall
- no new tools involved ( artifact management system )
- Same credentials scheme as your source code ( even ssh )
- easy to trigger in pipelines based on tags or branch updates
- no need for release drives/shares which is hard to maintain and no traces
- measurements of time as the commit and tags and improvements are easy to extract over time 
- Git's normal garbage collection takes care of the details for cleaning

### producer
- Add the git-artifact repo as submodule to let the make system output to the git-artifact repo directory ready to commit
- easy to append artifacts as stages evolves with more artifacts
- no need to zip before upload nor unzip after download
- easy to addition information, environment, tools and git srouce sha1 in the artifact for traceability and later reproduction

### consumer
- easy to use a submodule for other repo as a dependency 
- even a consumer can be a producer adding further artifacts on top the consumed commit with a new commit and tag
- git understand the content in workspace and git clean does not remove artifacts with structure rather than zipping and un-zipping 

## The concept

## Prerequisites 
We are using the full freedom and powers of Git, so it is required to have delete/force push permissions to branches in order move branch heads to new artifacts that is not fast forwards

### Advises
Define a tag- and branch-name strategy for each "layer" of git-artifacts. This is main of appending and several artifacts are in the same repository. It could be `unsigned/latest` and `signed/latest` for branches. `1.1.8928/unsigned`, `1.1.8928/signed`, `1.1.8928/targettest-passed`, `1.1.8928/targettest-failed`, `1.1.8928/regression-passed` etc..    

## Initialize
```
git init
touch .gitignore && git add .gitignore
touch .gitattributes && git add .gitattributes
git commit -m "Initialize the git artifact repository"
git remote add origin <repo-url>
git push origin master/main
```

## Adding a new artifact
```
git clone -b master -depth 1 <repo-url>
:git add $file: || git add .
git commit -m "$message"
git tag -a -m "$message" $tag
git push origin $tag:refs/tags/$tag
git push origin latest --force
```
  
## consume the latest git-artifact
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

## pruning / cleaning artifacts
### using `git log` and get tags with a certains pattern 
### 

## Advanced

### cloning with filter
- only some repo managers

### LFS

### Dual artifactory and git-artifact usages
- set your LFS store tp be Artifactory and then can normal artifacts via upload and LFS have tracability
