#!/bin/sh
# to change
cd /www/izishirt
/usr/local/bin/rake products:fast_preview_generator RAILS_ENV=production

/bin/bash /www/izishirt/lib/exec_fast_product_preview_generator.sh &
