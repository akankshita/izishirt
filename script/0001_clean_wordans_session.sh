#/bin/bash
RAILS_ENV=production
cd /var/www/rails/rezopdr/current
ruby ./script/runner \
'ActiveRecord::Base.connection.delete(
"DELETE FROM sessions WHERE updated_at < DATE_SUB(now(), INTERVAL 1 HOUR)")'
