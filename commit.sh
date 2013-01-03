#!/bin/sh

my_branch=$1

git checkout $my_branch
git commit -a
git pull origin $my_branch
git push origin $my_branch
