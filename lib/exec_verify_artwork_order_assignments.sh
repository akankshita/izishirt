#!/bin/sh
# to change
cd /www/izishirt
/usr/local/bin/rake artwork:verify_artwork_order_assignments RAILS_ENV=production
