#!/bin/sh
# to change
cd /www/izishirt
/usr/local/bin/rake cache:clear_daily_html RAILS_ENV=production
