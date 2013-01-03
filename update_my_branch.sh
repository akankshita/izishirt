#!/bin/sh

my_branch=$1

git checkout master
git pull origin master
git checkout $my_branch
git merge master
