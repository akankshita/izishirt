#!/bin/sh
# to change
cd /www/izishirt
/usr/local/bin/rake images:delete_invalid_images RAILS_ENV=production
