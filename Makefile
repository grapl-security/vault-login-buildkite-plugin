COMPOSE_USER=$(shell id -u):$(shell id -g)

# Linting
########################################################################

.PHONY: lint
lint: lint-plugin lint-bash

.PHONY: lint-plugin
lint-plugin:
	docker-compose run --rm plugin-linter

.PHONY: lint-bash
lint-bash:
	./pants lint ::

# Formatting
########################################################################

.PHONY: format
format: format-bash

.PHONY: format-bash
format-bash:
	./pants fmt ::

# Testing
########################################################################

.PHONY: test
test: test-plugin

.PHONY: test-plugin
test-plugin:
	docker-compose run --rm plugin-tester

.PHONY: all
all: format lint test
