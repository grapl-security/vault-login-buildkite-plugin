DOCKER_COMPOSE_CHECK := docker compose run --rm

.DEFAULT_GOAL=all

# Linting
########################################################################

.PHONY: lint
lint: lint-plugin lint-shell

.PHONY: lint-plugin
lint-plugin:
	$(DOCKER_COMPOSE_CHECK) plugin-linter

.PHONY: lint-shell
lint-shell:
	./pants lint ::

# Formatting
########################################################################

.PHONY: format
format: format-shell

.PHONY: format-shell
format-shell:
	./pants fmt ::

# Testing
########################################################################

.PHONY: test
test: test-shell test-plugin

.PHONY: test-shell
test-shell:
	./pants test ::

.PHONY: test-plugin
test-plugin:
	$(DOCKER_COMPOSE_CHECK) plugin-tester

.PHONY: all
all: format lint test
