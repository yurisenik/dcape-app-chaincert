SHELL := /bin/bash
.DEFAULT_GOAL := help

CFG ?= .env
APP_NAME ?= chaincert
APP_ROOT ?= $(CURDIR)
DCAPE_ROOT ?= /opt/dcape
USE_TLS ?= true
USE_DB ?= no
# This package defines the full service, including its Traefik labels.
USE_DCAPE_DC := no
SOURCE_REPO ?= https://github.com/yurisenik/chaincert.git
SOURCE_REF ?= v1.1.0
SOURCE_CONTEXT ?= $(SOURCE_REPO)\#$(SOURCE_REF)
IMAGE ?= chaincert
IMAGE_VER ?= $(SOURCE_REF)

-include $(DCAPE_ROOT)/.dcape.env
-include $(CFG)
DCAPE_DOMAIN ?= example.org
DCAPE_TAG ?= dcape
DCAPE_NET ?= $(DCAPE_TAG)
APP_SITE ?= $(APP_NAME).$(DCAPE_DOMAIN)
APP_TAG ?= $(subst .,-,$(APP_SITE))
PROJECT_NAME ?= $(APP_TAG)
export

.PHONY: dc up down
dc:
	docker compose --env-file "$(CFG)" -f docker-compose.yml -p "$(PROJECT_NAME)" $(CMD)
up: CMD=up -d
up: dc
down: CMD=down
down: dc

.PHONY: help config build source build-local update logs
help:
	@echo 'Copy .env.example to .env; edit APP_SITE and DCAPE_NET.'
	@echo 'make config | build | up | logs | down | source | build-local | update'

config:
	$(MAKE) dc CMD=config

build:
	$(MAKE) dc CMD='build --pull app'

# Checkout only inside the ignored .source directory. Refuse local changes.
source:
	@if [ ! -d .source/chaincert/.git ]; then \
	  mkdir -p .source/chaincert && git -C .source/chaincert init -q || exit 1; \
	fi; \
	test -z "$$(git -C .source/chaincert status --porcelain)" || { echo 'Source checkout has local changes; preserve them before updating.' >&2; exit 1; }; \
	git -C .source/chaincert fetch --depth 1 "$(SOURCE_REPO)" "$(SOURCE_REF)" && \
	git -C .source/chaincert checkout --detach FETCH_HEAD

build-local: source
	$(MAKE) build SOURCE_CONTEXT="$(CURDIR)/.source/chaincert"

update: build
	$(MAKE) up

logs:
	$(MAKE) dc CMD='logs --tail 100 -f app'
