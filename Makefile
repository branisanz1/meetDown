CONSOLE=bin/console
DC=docker-compose
HAS_DOCKER:=$(shell command -v $(DC) 2> /dev/null)

ifdef HAS_DOCKER
	ifdef PHP_ENV
		EXECROOT=$(DC) exec -e PHP_ENV=$(PHP_ENV) php
		EXEC=$(DC) exec -e PHP_ENV=$(PHP_ENV) php
	else
		EXECROOT=$(DC) exec php
		EXEC=$(DC) exec php
	endif
else
	EXECROOT=
	EXEC=
endif

.DEFAULT_GOAL := help

.PHONY: help ## Generate list of targets with descriptions
help:
		@grep '##' Makefile \
		| grep -v 'grep\|sed' \
		| sed 's/^\.PHONY: \(.*\) ##[\s|\S]*\(.*\)/\1:\t\2/' \
		| sed 's/\(^##\)//' \
		| sed 's/\(##\)/\t/' \
		| expand -t14

##
## Project setup & day to day shortcuts
##---------------------------------------------------------------------------

.PHONY: start ## Start the project (Install in first place)
start: docker-compose.override.yml
	$(DC) pull || true
	$(DC) build
	$(DC) up -d
	$(EXEC) composer install
	$(EXEC) $(CONSOLE) doctrine:database:create --if-not-exists
	$(EXEC) $(CONSOLE) doctrine:schema:update --force
	$(EXEC) $(CONSOLE) make:migration
	$(EXEC) $(CONSOLE) hautelook:fixtures:load -q

.PHONY: stop ## stop the project
stop:
	$(DC) down

.PHONY: exec ## Run bash in the php container
exec:
	$(EXEC) /bin/bash

.PHONY: test ## Start an analyze of the code and return a checkup
test:
	$(EXEC) vendor/bin/phpcs --ignore=*/Migrations/* src
	$(EXEC) vendor/bin/phpstan analyse src -c config/phpstan/phpstan.neon -l 6


.PHONY: testF ## Start an analyze of the code and return a checkup
testF:
	$(EXEC) vendor/bin/phpcbf src

##
## Dependencies Files
##---------------------------------------------------------------------------