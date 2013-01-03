#!/bin/sh
# to change
cd /www/izishirt
/usr/local/bin/rake back_up_last_day_images RAILS_ENV=production
