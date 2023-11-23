APP = app

TS=$(shell date +%Y-%m-%d-%H-%M-%S)

all: $(APP)

$(APP): webapp/golang/*.go
	$(MAKE) -C webapp/golang app

# @ ~/.ssh/config
# Host isu01
#  HostName (EC2 public IP)
#  IdentityFile ~/.ssh/hoge.pem
#  User isucon
#  Port 22

switch-go:
	ssh isu01 "sudo systemctl stop isu-ruby"
	ssh isu01 "sudo systemctl disable isu-ruby"
	ssh isu01 "sudo systemctl start isu-go"
	ssh isu01 "sudo systemctl enable isu-go"

scp: $(APP)
	scp ./webapp/golang/$(APP) isucon@isu01:/home/isucon/private_isu/webapp/golang/$(APP) & \
	wait

stop:
	ssh isu01 "sudo systemctl stop isu-go" & \
	wait

start:
	ssh isu01 "sudo systemctl start isu-go" & \
	wait

deploy: $(APP) stop scp start

restart:
	ssh isu01 "sudo systemctl restart isu-go" & \
	wait

status:
	ssh isu01 "sudo systemctl status isu-go"

scp-nginx:
	ssh isu01 "sudo dd of=/etc/nginx/nginx.conf" < ./etc/nginx/nginx.conf
	ssh isu01 "sudo dd of=/etc/nginx/conf.d/default.conf" < ./etc/nginx/conf.d/default.conf

reload-nginx:
	ssh isu01 "sudo systemctl reload nginx.service"

deploy-nginx: scp-nginx reload-nginx

rotate-nginx:
	ssh isu01 sudo sh -c 'test -f /var/log/nginx/access.log && mv -f /var/log/nginx/access.log /var/log/nginx/access.log.$(TS) || true'
	ssh isu01 'sudo kill -USR1 `cat /var/run/nginx.pid`'

PATHS='/image/[0-9]+,/posts/[0-9]+,/@[_a-zA-Z0-9]+'

alp:
	ssh isu01 sudo alp ltsv --file /var/log/nginx/access.log -m '$(PATHS)' --sort sum -o count,method,uri,min,avg,max,sum --reverse

# alp:
# 	ssh isu01 sudo alp ltsv --file /var/log/nginx/access.log -m '$(PATHS)' --sort sum -o count,method,uri,min,avg,max,sum --reverse | notify_slack -c notify-slack.toml -snippet -filename alp.txt

pt-query-digest:
	ssh isu01 sudo pt-query-digest /var/log/mysql/mysql-slow.log

rotate-mysql-log:
	ssh isu01 sudo sh -c 'test -f /var/log/mysql/mysql-slow.log && mv -f /var/log/mysql/mysql-slow.log /var/log/mysql/mysql-slow.log.$(TS) || true'
	ssh isu01 sudo sh -c 'systemctl restart mysql'

after-bench: rotate-mysql-log rotate-nginx

# scp-mariadb:
# 	ssh isu01 "sudo dd of=/etc/mysql/mariadb.conf.d/50-server.cnf" < ./etc/mysql/mariadb.conf.d/50-server.cnf
# 	ssh isu02 "sudo dd of=/etc/mysql/mariadb.conf.d/50-server.cnf" < ./etc/mysql/mariadb.conf.d/50-server.cnf
# 	ssh isu03 "sudo dd of=/etc/mysql/mariadb.conf.d/50-server.cnf" < ./etc/mysql/mariadb.conf.d/50-server.cnf

# restart-mariadb:
# 	ssh isu01 "sudo systemctl restart mariadb.service" & \
# 	ssh isu02 "sudo systemctl restart mariadb.service" & \
# 	ssh isu03 "sudo systemctl restart mariadb.service" & \
# 	wait

# deploy-mariadb: scp-mariadb restart-mariadb

# scp-redis:
# 	ssh isu02 "sudo dd of=/etc/redis/redis.conf" < ./etc/redis/redis.conf

# restart-redis:
# 	ssh isu02 "sudo systemctl restart redis-server.service"

# deploy-redis: scp-redis restart-redis