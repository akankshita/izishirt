#!/bin/bash 
RAILS_ENV=production 
cd /www/production/izishirt/current
/usr/bin/ruby ./script/runner 'ActiveRecord::Base.connection.delete("DELETE FROM sessions WHERE updated_at < DATE_SUB(now(), INTERVAL 2 HOUR)")' 
#echo "" > log/mongrel.log
#echo "" > log/production.log
