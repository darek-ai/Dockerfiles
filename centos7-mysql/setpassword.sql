
use mysql;

set password for root@'%' = password('123456');

grant all on *.* to root@'%' identified by '123456' with grant option;

flush privileges;
