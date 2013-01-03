#!/bin/bash
mysql --user=izishirt --password='Ch33Zc4Tz8493' -e "use izishirt; delete from sessions where (updated_at < DATE_SUB(CURDATE(),INTERVAL 8 DAY)) OR (updated_at = created_at AND created_at < DATE_SUB(NOW(),INTERVAL 1 HOUR));"
