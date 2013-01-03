#!/bin/sh
# to change
cd /www/izishirt
/usr/local/bin/rake order:check_statuses RAILS_ENV=production
