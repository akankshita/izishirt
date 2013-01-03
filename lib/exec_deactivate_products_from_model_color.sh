#!/bin/sh
# to change
cd /www/izishirt
/usr/local/bin/rake products:deactivate_from_model_color RAILS_ENV=production
