PREPARE=.docker/prepare.sh
DOCKER_UP_ONLY_RUNNING=$(HOME)/dev/docker/bin/docker-compose_up_only-running.sh
MYSQL=.bin/mysql
COMPOSER=.bin/composer

-include .env

.PHONY: usage
usage:
	@grep -v PHONY Makefile


### Init

.PHONY: init
init: git-clone docker-pull docker-up

.PHONY: init-web
init-web: clean-all db-wait
	cd vigisade-web && make packages-init
	cd vigisade-web && make assets-init
	cd vigisade-web && make db-init
	cd vigisade-web && make db-migrate

.PHONY: init-pwa
init-pwa:
	cd vigisade-pwa && make init-packages
	cd vigisade-pwa && make build-dev

.PHONY: init-pwa-prod
init-pwa-prod:
	cd vigisade-pwa && make init-packages
	cd vigisade-pwa && make build-prod

.PHONY: db-wait
db-wait: docker-up
	.docker/exec.sh -T php dockerize -wait tcp://db:3306 -timeout 60s

.env : $(PREPARE)
	$(PREPARE)

.PHONY: docker-prepare
docker-prepare:
	$(PREPARE)

.PHONY: %-on
%-on:
	$(PREPARE) + $(*F)

.PHONY: %-off
%-off:
	$(PREPARE) - $(*F)


.PHONY: init-host
init-host:
	echo 127.0.24.1 vigisade.dev.brocelia.net | sudo tee -a /etc/hosts


### Git

.PHONY: update
update: git-pull init-web-packages

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
	git clone -b $(TESTB) --single-branch git@gitlab.brocelia.net:sade/vigisade/vigisade-web.git
	git clone git@gitlab.brocelia.net:sade/vigisade/vigisade-pwa.git


### Docker

.PHONY: docker-update
docker-update: docker-pull docker-up

.PHONY: docker-pull
docker-pull: docker-prepare
	docker-compose pull

.PHONY: up
up: docker-up

.PHONY: docker-up
docker-up: docker-prepare
	docker-compose up -d --remove-orphans

.PHONY: docker-up-force
docker-up-force: docker-prepare
	docker-compose up -d --remove-orphans --force-recreate

.PHONY: up-or
up-or: docker-up-only-running

.PHONY: docker-up-only-running
docker-up-only-running:
	$(DOCKER_UP_ONLY_RUNNING)

.PHONY: ps
ps: docker-ps

.PHONY: docker-ps
docker-ps: docker-prepare
	docker-compose ps

.PHONY: restart
restart: docker-restart

.PHONY: docker-restart
docker-restart: docker-prepare
	docker-compose restart

.PHONY: stop
stop: docker-stop

.PHONY: docker-stop
docker-stop: docker-prepare
	docker-compose stop

.PHONY: docker-clean-containers
docker-clean-containers: docker-prepare
	docker rm -f -v $$(docker ps -qa -f name=^$(COMPOSE_PROJECT_NAME)_) || true

.PHONY: docker-clean-volumes
docker-clean-volumes: docker-prepare
	docker volume rm $$(docker volume ls -q -f name=^$(COMPOSE_PROJECT_NAME)_) || true

.PHONY: docker-clean-all-but-net
docker-clean-all-but-net: docker-clean-containers docker-clean-volumes

.PHONY: docker-clean
docker-clean: docker-prepare
	docker-compose down --remove-orphans || true

.PHONY: docker-clean-all
docker-clean-all: docker-prepare
	docker-compose down -v --remove-orphans || true

.PHONY: logs
logs: docker-logs

.PHONY: docker-logs
docker-logs: docker-up
	docker-compose logs -f --tail=0

.PHONY : clean-all
clean-all : docker-clean-all
