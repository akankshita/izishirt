#!/bin/sh

my_branch=$1

sudo git checkout master
sudo git pull origin master
sudo git merge $my_branch
sudo git push origin master
sudo git checkout $my_branch

