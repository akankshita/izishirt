#!/bin/bash
#Remove db dumps older then 8 days
cd /home/adam/db_dumps
find . -mtime +6 |xargs -ivar rm "var"
