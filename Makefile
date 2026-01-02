SHELL := /usr/bin/env bash
.SHELLFLAGS := -euo pipefail -c

# Reduce noise from nested make invocations
MAKEFLAGS += --no-print-directory

# Variables
VERSION_FILE = version.txt      # version file
BUMPVER_FILE = .bumpversion.cfg # bump2version config file
BRANCH = main
BUMP_PART = patch               # default bump2version part (patch, minor, major)
TAG_PREFIX = v
DATA_DIR = data
VALID_RELEASE_TYPES = patch minor major

DEV_REQUIREMENTS = ./requirements/development.txt
DEV_PORT ?= 1313

# -----------------------------
# Dockerized Hugo toolchain
# -----------------------------
# Prebuilt multi-arch image (built/pushed from separate repo)
HUGO_IMAGE ?= wyllie/hugo:latest
HUGO_WORKDIR ?= /app

UID := $(shell id -u)
GID := $(shell id -g)

# Cache volumes to avoid re-downloading Hugo/Go modules each run
# (names are prefixed by the repo folder name to prevent collisions)
CACHE_PREFIX := $(shell basename "$(PWD)")
HUGO_CACHE_VOL ?= $(CACHE_PREFIX)-hugo-cache
GO_MOD_CACHE_VOL ?= $(CACHE_PREFIX)-gomod-cache

# Cache locations inside the container
HUGO_CACHEDIR ?= /cache/hugo
GOMODCACHE ?= /cache/go/pkg/mod
GOCACHE ?= /cache/go/build

# Root run helper (used only to initialize/chown cache volumes)
DOCKER_RUN_ROOT = docker run --rm -it \
	-e HUGO_CACHEDIR=$(HUGO_CACHEDIR) \
	-e GOMODCACHE=$(GOMODCACHE) \
	-e GOCACHE=$(GOCACHE) \
	-v "$(HUGO_CACHE_VOL):$(HUGO_CACHEDIR)" \
	-v "$(GO_MOD_CACHE_VOL):/cache/go" \
	-v "$(PWD):$(HUGO_WORKDIR)" \
	-w "$(HUGO_WORKDIR)"

# Non-root run helper (default)
DOCKER_RUN = docker run --rm -it \
	-u $(UID):$(GID) \
	-e HUGO_CACHEDIR=$(HUGO_CACHEDIR) \
	-e GOMODCACHE=$(GOMODCACHE) \
	-e GOCACHE=$(GOCACHE) \
	-v "$(HUGO_CACHE_VOL):$(HUGO_CACHEDIR)" \
	-v "$(GO_MOD_CACHE_VOL):/cache/go" \
	-v "$(PWD):$(HUGO_WORKDIR)" \
	-w "$(HUGO_WORKDIR)"

DOCKER_RUN_DEV = $(DOCKER_RUN) -p $(DEV_PORT):1313

# Compute host IP for baseURL (works on macOS + Linux; falls back to localhost)
HOST_IP := $(shell ipconfig getifaddr en0 2>/dev/null || \
	ipconfig getifaddr en1 2>/dev/null || \
	hostname -I 2>/dev/null | awk '{print $$1}' || \
	echo localhost)

# Hugo config args are repo-specific (override as needed)
HUGO_CONFIG_ARGS ?= --config hugo.toml

# Ensure baseURL matches the host (useful for mobile testing on LAN)
HUGO_BASEURL ?= http://$(HOST_IP):$(DEV_PORT)/

# Default server args (can be overridden)
HUGO_SERVER_ARGS ?= -D \
	--disableFastRender --ignoreCache \
	$(HUGO_CONFIG_ARGS) \
	--bind 0.0.0.0 \
	--baseURL=$(HUGO_BASEURL)

# Release safety latch (must be explicitly enabled)
RELEASE ?=

# ---- Release Guards ----

require_release:
	@if [ -z "$(RELEASE)" ]; then \
	  echo "❌ Refusing to run release without explicit confirmation."; \
	  echo "   Use: make release RELEASE=patch|minor|major"; \
	  exit 2; \
	fi
	@if ! echo "$(VALID_RELEASE_TYPES)" | grep -qw "$(RELEASE)"; then \
    	  echo "❌ Invalid RELEASE type: '$(RELEASE)'"; \
    	  echo "   Valid values: patch, minor, major"; \
    	  exit 2; \
	fi

check_version:
	@V=$$(tr -d ' \t\n\r' < $(VERSION_FILE) 2>/dev/null || true); \
	if [ -z "$$V" ]; then \
	  echo "❌ $(VERSION_FILE) is empty or missing"; \
	  exit 2; \
	fi; \
	if ! echo "$$V" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$$'; then \
	  echo "❌ $(VERSION_FILE) must contain a SemVer like 1.2.3 (got: '$$V')"; \
	  exit 2; \
	fi

check_branch:
	@b=$$(git rev-parse --abbrev-ref HEAD); \
	[ "$$b" = "$(BRANCH)" ] || { echo "❌ Must release from $(BRANCH), currently $$b"; exit 2; }

check_clean:
	@git diff --quiet && git diff --cached --quiet || { echo "❌ Working tree is not clean"; exit 2; }

check_up_to_date:
	@git fetch origin $(BRANCH) >/dev/null 2>&1; \
	l=$$(git rev-parse HEAD); r=$$(git rev-parse origin/$(BRANCH)); \
	[ "$$l" = "$$r" ] || { echo "❌ $(BRANCH) is not up to date with origin/$(BRANCH)"; exit 2; }

check_tags:
	@CUR=$$(tr -d ' \t\n\r' < $(VERSION_FILE) 2>/dev/null || true); \
	if [ -z "$$CUR" ]; then \
	  echo "❌ $(VERSION_FILE) is empty or missing"; \
	  exit 2; \
	fi; \
	IFS='.' read -r MA MI PA <<< "$$CUR"; \
	case "$(RELEASE)" in \
	  major) MA=$$((10#$$MA + 1)); MI=0; PA=0 ;; \
	  minor) MI=$$((10#$$MI + 1)); PA=0 ;; \
	  patch) PA=$$((10#$$PA + 1)) ;; \
	  *) echo "❌ Invalid RELEASE type: '$(RELEASE)'"; echo "   Valid values: patch, minor, major"; exit 2 ;; \
	esac; \
	NEXT="$$MA.$$MI.$$PA"; \
	ROOT="$(TAG_PREFIX)$$NEXT"; \
	MOD="module/$(TAG_PREFIX)$$NEXT"; \
	git rev-parse "$$ROOT" >/dev/null 2>&1 && { echo "❌ Tag $$ROOT already exists"; exit 2; } || true; \
	git rev-parse "$$MOD"  >/dev/null 2>&1 && { echo "❌ Tag $$MOD already exists"; exit 2; } || true

check_gh:
	@gh auth status >/dev/null 2>&1 || { echo "❌ GitHub CLI not authenticated (run gh auth login)"; exit 2; }

preflight: check_version check_branch check_clean check_up_to_date check_tags check_gh

# Get the version from the version file
VERSION := $(shell cat $(VERSION_FILE))
FULL_TAG = $(TAG_PREFIX)$(VERSION)
VERSION_JSON = $(DATA_DIR)/version.json

# Default target to create a tag and a release
release: require_release preflight
	@$(MAKE) BUMP_PART=$(RELEASE) bump_version version_json commit_and_push create_tag_release

# Different release types - release-patch is the default
release-patch:
	$(MAKE) RELEASE=patch release

release-minor:
	$(MAKE) RELEASE=minor release

release-major:
	$(MAKE) RELEASE=major release


check:
	@echo "Root tag is $(FULL_TAG)"
	@echo "Module tag is module/$(FULL_TAG)"

init:
	pip install --upgrade pip
	pip install -r $(DEV_REQUIREMENTS)

# Run a local server for development (Dockerized Hugo toolchain)
server: cache_ensure clean
	@echo "Using IP: $(HOST_IP)"; \
	$(DOCKER_RUN_DEV) $(HUGO_IMAGE) /bin/bash -lc 'hugo server $(HUGO_SERVER_ARGS)'

# Target to bump version using bump2version
bump_version:
	@echo "→ Updating $(BRANCH) and bumping version ($(BUMP_PART))"
	@git checkout $(BRANCH)
	@git pull origin $(BRANCH)
	@bump2version $(BUMP_PART)

# Generate/refresh Hugo data file with the latest tag and date
version_json:
	@VTXT=$$(tr -d ' \t\n\r' < $(VERSION_FILE) 2>/dev/null || true); \
	[ -n "$$VTXT" ] || { echo "❌ $(VERSION_FILE) is empty or missing"; exit 2; }; \
	TAG="$(TAG_PREFIX)$$VTXT"; \
	DATE=$$(git log -1 --format=%cs HEAD); \
	mkdir -p $(DATA_DIR); \
	echo "{ \"tag\": \"$$TAG\", \"date\": \"$$DATE\" }" > $(VERSION_JSON); \
	echo "Wrote $(VERSION_JSON) -> $$TAG ($$DATE)"

# Target to commit and push version bump changes
commit_and_push:
	@echo "→ Committing version bump"
	@git add $(VERSION_FILE) $(BUMPVER_FILE) $(VERSION_JSON)
	@VERSION_NEW=$$(cat $(VERSION_FILE)); \
	git commit -m "Bump version to $$VERSION_NEW"
	@echo "→ Pushing $(BRANCH)"
	@git push origin $(BRANCH)

# Optional: commit the generated data/version.json back to the repo
about_commit: version_json
	@git add $(VERSION_JSON)
	@git commit -m "chore: update version.json for $(FULL_TAG)" || true
	@git push origin $(BRANCH) || true

# Target to create a Git tag
create_tag_release:
	@VTXT=$$(tr -d ' \t\n\r' < $(VERSION_FILE) 2>/dev/null || true); \
	[ -n "$$VTXT" ] || { echo "❌ $(VERSION_FILE) is empty or missing"; exit 2; }; \
	ROOT_TAG="$(TAG_PREFIX)$$VTXT"; \
	MODULE_TAG="module/$(TAG_PREFIX)$$VTXT"; \
	echo "→ Tagging $$ROOT_TAG and $$MODULE_TAG"; \
	\
	git tag "$$ROOT_TAG"; \
	git tag "$$MODULE_TAG"; \
	git push origin "$$ROOT_TAG"; \
	git push origin "$$MODULE_TAG"; \
	\
	echo "→ Creating GitHub release $$ROOT_TAG"; \
	gh release create "$$ROOT_TAG" \
		--title "Release $$ROOT_TAG" \
		--generate-notes



# Clean out Hugo build artifacts
clean:
	@rm -rf public resources .hugo_cache || true

# Pull the prebuilt multi-arch image
pull:
	docker pull $(HUGO_IMAGE)

# Ensure cache volumes exist and warm them only if empty
cache_ensure:
	@docker volume inspect $(HUGO_CACHE_VOL) >/dev/null 2>&1 || docker volume create $(HUGO_CACHE_VOL) >/dev/null
	@docker volume inspect $(GO_MOD_CACHE_VOL) >/dev/null 2>&1 || docker volume create $(GO_MOD_CACHE_VOL) >/dev/null
	@$(DOCKER_RUN_ROOT) $(HUGO_IMAGE) /bin/bash -lc '\
		mkdir -p "$(HUGO_CACHEDIR)" "$(GOMODCACHE)" "$(GOCACHE)"; \
		chown -R $(UID):$(GID) /cache/go "$(HUGO_CACHEDIR)"'
	@$(DOCKER_RUN) $(HUGO_IMAGE) /bin/bash -lc '\
		if [ -d "$(GOMODCACHE)" ] && [ -w "$(GOMODCACHE)" ] && [ "$$(ls -A "$(GOMODCACHE)" 2>/dev/null | wc -l | tr -d " ")" -gt 0 ]; then \
			echo "✅ Hugo/Go module cache already populated"; \
		else \
			echo "⬇️  Warming Hugo/Go module cache (first run)"; \
			hugo mod get && hugo mod tidy; \
		fi'

# Warm the cache (downloads Hugo modules into the mounted caches)
cache_warm:
	@$(DOCKER_RUN) $(HUGO_IMAGE) /bin/bash -lc 'hugo mod get && hugo mod tidy'

# Update Hugo modules (equivalent to local "hugo mod get -u")
modules_update:
	@$(DOCKER_RUN) $(HUGO_IMAGE) /bin/bash -lc 'hugo mod get -u && hugo mod tidy'

# Clear the cached volumes (forces fresh downloads next run)
cache_clear:
	-docker volume rm $(HUGO_CACHE_VOL) $(GO_MOD_CACHE_VOL)

# Show tool versions from inside the container
versions:
	@$(DOCKER_RUN) $(HUGO_IMAGE) /bin/bash -lc 'hugo version; echo; sass --version; echo; command -v node >/dev/null 2>&1 && node --version || echo "node: (not installed)"; command -v npm >/dev/null 2>&1 && npm --version || echo "npm: (not installed)"; echo; aws --version'

# Open an interactive shell in the container (mounted to this repo)
shell:
	@$(DOCKER_RUN_DEV) $(HUGO_IMAGE) /bin/bash

# Rebuild site from scratch (Dockerized Hugo toolchain)
rebuild: cache_ensure clean
	@$(DOCKER_RUN) $(HUGO_IMAGE) /bin/bash -lc 'hugo --gc --cleanDestinationDir'

.DEFAULT_GOAL := help

help:
	@echo ""
	@echo "Safe targets:"
	@echo "  make server"
	@echo "  make clean"
	@echo "  make rebuild"
	@echo "  make pull"
	@echo "  make versions"
	@echo "  make shell"
	@echo "  make modules_update"
	@echo "  make cache_clear"
	@echo ""
	@echo "Release (explicit opt-in required):"
	@echo "  make release RELEASE=patch"
	@echo "  make release RELEASE=minor"
	@echo "  make release RELEASE=major"
	@echo ""

.PHONY: check init server bump_version commit_and_push create_tag_release clean rebuild version_json about_commit help require_release preflight check_branch check_clean check_up_to_date check_tags check_gh check_version pull versions shell cache_ensure cache_warm modules_update cache_clear
