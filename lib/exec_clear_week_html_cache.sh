#!/bin/sh
# to change
cd /www/izishirt
/usr/local/bin/rake cache:clear_week_html RAILS_ENV=production
/usr/local/bin/rake cache:clear_francis_cache RAILS_ENV=production