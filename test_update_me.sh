#!/bin/sh

my_branch=$1

sudo git checkout $my_branch
sudo git pull origin $my_branch
