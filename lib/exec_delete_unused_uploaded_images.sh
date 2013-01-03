#!/bin/sh
# to change
cd /www/izishirt
/usr/local/bin/rake images:delete_unused_uploaded_images RAILS_ENV=production
