call mysql -u root -e "drop database izishirt_development; create database izishirt_development;"
call rake db:migrate
cd..
call ruby script/server