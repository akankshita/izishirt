#!/bin/sh

DATE=`date +"%Y-%m-%d"`
DESCRIPTION=$1
NEW_BRANCH=$2
MY_NAME="martin"
LOCAL_TRUNK_REPOS="izishirt"
BRANCH_FULL_NAME="$DATE"_"$MY_NAME"_"$NEW_BRANCH"

echo "TRUNK to /branches/$BRANCH_FULL_NAME"
svn copy -m \"$DESCRIPTION\" http://svn.studiocodency.com/code/izishirt/trunk http://svn.studiocodency.com/code/izishirt/branches/"$BRANCH_FULL_NAME"

echo "CHECKOUT /branches/$BRANCH_FULL_NAME to $BRANCH_FULL_NAME"
svn co http://svn.studiocodency.com/code/izishirt/branches/"$BRANCH_FULL_NAME" $BRANCH_FULL_NAME

cur_dir=`pwd`

ln -f -s "$cur_dir"/"$LOCAL_TRUNK_REPOS"/public/izishirtfiles "$cur_dir"/"$BRANCH_FULL_NAME"/public/izishirtfiles
