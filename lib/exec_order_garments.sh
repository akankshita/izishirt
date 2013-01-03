#!/bin/sh
# to change
cd /www/izishirt
/usr/local/bin/rake mails:order_garments RAILS_ENV=production
