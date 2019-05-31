INIT_ENV=.docker/init-env.sh
INIT=.docker/init.sh
EXPORT_DUMP=.bin/export-dump.sh
PHP=.bin/php -T
COMPOSER=.bin/composer -T --ansi


### Makefile

.PHONY: usage
usage:
	@grep -v PHONY Makefile


### Init

.PHONY: init
init: git-clone docker-pull

.PHONY: init-web
init-web: init-packages init-db

.PHONY: init-packages
init-packages:
	cd vigisade-web && make composer-install

.PHONY: init-db
init-db:
	cd vigisade-web && make init-db

.env: $(INIT_ENV)
	$(INIT_ENV)

.PHONY: init-host
init-host:
	echo 127.0.24.1 www-dev.vigisade.com | sudo tee -a /etc/hosts

### Git

.PHONY: git-pull
git-pull:
	@for project in vigisade-*; do \
		echo $$project:; \
		git -C $$project pull; \
		echo; \
	done

.PHONY: git-clone
git-clone:
	rm -rf vigisade-*
	git clone git@gitlab.brocelia.net:sade/vigisade/vigisade-web.git

### Docker

.PHONY : docker-update
docker-update : docker-pull docker-up

.PHONY : docker-pull
docker-pull : .env
	docker-compose pull

.PHONY : up
up : docker-up

.PHONY : stop
stop : docker-stop

.PHONY : docker-up
docker-up : docker-prepare
	docker-compose up -d --remove-orphans

.PHONY : docker-up-force
docker-up-force : docker-prepare
	docker-compose up -d --remove-orphans --force-recreate

.PHONY : docker-stop
docker-stop :
	docker-compose stop

.PHONY : docker-clean-all
docker-clean-all : .env
	docker-compose down --remove-orphans -v

.PHONY : docker-prepare
docker-prepare : .env

.PHONY: docker-pull
docker-pull: docker-prepare
	docker-compose pull

.PHONY : clean-all
clean-all : docker-clean-all clean-conf clean-libs
