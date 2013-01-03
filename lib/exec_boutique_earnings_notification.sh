#!/bin/sh
# to change
cd /www/izishirt
/usr/local/bin/rake mails:boutique_earnings_notification RAILS_ENV=production
