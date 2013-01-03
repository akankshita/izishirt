#!/bin/sh
# to change
cd /www/izishirt
/usr/local/bin/rake garments:reorder_back_order RAILS_ENV=production
