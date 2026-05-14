# ============================================================
# 1. help (default target)
# ============================================================
help:
	@echo "================================================"
	@echo "       $(OWNER)/$(PROJECT_NAME) by Startr.Cloud"
	@echo "================================================"
	@echo "This is the default make command."
	@echo "This command lists available make commands."
	@echo ""
	@echo "Usage example:"
	@echo "    make aider"
	@echo ""
	@echo "Available make commands:"
	@echo ""
	@LC_ALL=C $(MAKE) -pRrq -f $(firstword $(MAKEFILE_LIST)) : 2>/dev/null | \
		awk -v RS= -F: '/(^|\n)# Files(\n|$$)/,/(^|\n)# Finished Make data base/ { \
		if ($$1 !~ "^[#.]") {print $$1}}' | \
		sort | \
		grep -E -v -e '^[^[:alnum:]]' -e '^$$@$$'
	@echo ""

# ============================================================
# 2. Dynamic variables
# ============================================================
PROJECTPATH := $(shell git rev-parse --show-toplevel)
PROJECT     := $(shell echo $$(basename $(PROJECTPATH)) | tr '[:upper:]' '[:lower:]')
FULL_BRANCH := $(shell git rev-parse --abbrev-ref HEAD)
BRANCH      := $(shell echo $(FULL_BRANCH) | sed 's/.*\///' | tr '[:upper:]' '[:lower:]')
TAG         := $(shell git describe --always --tag)

REMOTE_URL   := $(shell git config --get remote.origin.url 2>/dev/null || echo "unknown/unknown")
OWNER        := $(shell echo $(REMOTE_URL) | sed -E 's|.*[:/]([^/]+)/[^/]+(.git)?$$|\1|')
PROJECT_NAME := $(shell echo $(REMOTE_URL) | sed -E 's|.*[:/][^/]+/([^/]+)(.git)?$$|\1|' | sed 's/\.git$$//')

CONTAINER := $(PROJECT)-$(BRANCH)

# ============================================================
# 3. Load .env overrides
# ============================================================
-include .env

# Aider defaults (override in .env or on the command line)
AIDER_TAG   ?= latest
AIDER_MODEL ?=
AIDER_FLAGS ?=

# Working directory to mount into the container.
# Defaults to the current directory, but can be pointed at any project:
#   make aider WORK_DIR=~/Projects/my-web-app
#   cd ../some-project && make -C ../AI-Aider aider
WORK_DIR ?= $(shell pwd)

# Build docker env flags dynamically from whatever is set
DOCKER_ENV_FLAGS :=
ifdef OPENAI_API_KEY
DOCKER_ENV_FLAGS += -e OPENAI_API_KEY=$(OPENAI_API_KEY)
endif
ifdef ANTHROPIC_API_KEY
DOCKER_ENV_FLAGS += -e ANTHROPIC_API_KEY=$(ANTHROPIC_API_KEY)
endif
ifdef GROQ_API_KEY
DOCKER_ENV_FLAGS += -e GROQ_API_KEY=$(GROQ_API_KEY)
endif
ifdef OPENROUTER_API_KEY
DOCKER_ENV_FLAGS += -e OPENROUTER_API_KEY=$(OPENROUTER_API_KEY)
endif
ifdef OLLAMA_API_BASE
DOCKER_ENV_FLAGS += -e OLLAMA_API_BASE=$(OLLAMA_API_BASE)
endif

# Build model flag if set
ifdef AIDER_MODEL
DOCKER_MODEL_FLAG := --model $(AIDER_MODEL)
else
DOCKER_MODEL_FLAG :=
endif

# ============================================================
# 4. Aider targets (project-specific)
# ============================================================

aider_pull:
	docker pull paulgauthier/aider:$(AIDER_TAG)
	docker pull paulgauthier/aider-full:$(AIDER_TAG)

aider: ## Run Aider core image
	docker run -it --rm \
		--user $$(id -u):$$(id -g) \
		--volume $(WORK_DIR):/app \
		$(DOCKER_ENV_FLAGS) \
		paulgauthier/aider:$(AIDER_TAG) \
		$(DOCKER_MODEL_FLAG) $(AIDER_FLAGS)

aider_full: ## Run Aider full image (browser GUI, Playwright)
	docker run -it --rm \
		--user $$(id -u):$$(id -g) \
		--volume $(WORK_DIR):/app \
		$(DOCKER_ENV_FLAGS) \
		paulgauthier/aider-full:$(AIDER_TAG) \
		$(DOCKER_MODEL_FLAG) $(AIDER_FLAGS)

aider_ollama: ## Run Aider with Ollama (local models)
	docker run -it --rm \
		--user $$(id -u):$$(id -g) \
		--volume $(WORK_DIR):/app \
		-e OLLAMA_API_BASE=$${OLLAMA_API_BASE:-http://host.docker.internal:11434} \
		$(DOCKER_ENV_FLAGS) \
		paulgauthier/aider:$(AIDER_TAG) \
		--model $${AIDER_MODEL:-ollama/deepseek-coder-v2} $(AIDER_FLAGS)

aider_groq: ## Run Aider with Groq
	@if [ -z "$(GROQ_API_KEY)" ]; then \
		echo "Error: GROQ_API_KEY not set. Add it to .env or export it."; exit 1; \
	fi
	docker run -it --rm \
		--user $$(id -u):$$(id -g) \
		--volume $(WORK_DIR):/app \
		-e GROQ_API_KEY=$(GROQ_API_KEY) \
		paulgauthier/aider:$(AIDER_TAG) \
		--model $${AIDER_MODEL:-groq/llama-3.3-70b-versatile} $(AIDER_FLAGS)

aider_openrouter: ## Run Aider with OpenRouter
	@if [ -z "$(OPENROUTER_API_KEY)" ]; then \
		echo "Error: OPENROUTER_API_KEY not set. Add it to .env or export it."; exit 1; \
	fi
	docker run -it --rm \
		--user $$(id -u):$$(id -g) \
		--volume $(WORK_DIR):/app \
		-e OPENROUTER_API_KEY=$(OPENROUTER_API_KEY) \
		paulgauthier/aider:$(AIDER_TAG) \
		--model $${AIDER_MODEL:-openrouter/anthropic/claude-sonnet-4-6} $(AIDER_FLAGS)

aider_build: ## Build custom Aider image from local Dockerfile
	@if [ ! -f Dockerfile ]; then \
		echo "No Dockerfile found. Create one to extend the Aider image."; exit 1; \
	fi
	docker build -t $(CONTAINER):$(BRANCH) .

aider_run_custom: ## Run custom-built Aider image
	docker run -it --rm \
		--user $$(id -u):$$(id -g) \
		--volume $(WORK_DIR):/app \
		$(DOCKER_ENV_FLAGS) \
		$(CONTAINER):$(BRANCH) \
		$(DOCKER_MODEL_FLAG) $(AIDER_FLAGS)

# ============================================================
# 5. Docker lifecycle
# ============================================================

it_stop:
	-docker stop $(CONTAINER)
	-docker rm $(CONTAINER)

it_clean:
	docker image prune -f
	docker builder prune -f

it_gone: it_stop
	-docker rmi $(CONTAINER):$(BRANCH)

# ============================================================
# 6. show_vars
# ============================================================
show_vars:
	@echo "=== Dynamic Variables ==="
	@echo "PROJECTPATH=$(PROJECTPATH)"
	@echo "PROJECT=$(PROJECT)"
	@echo "OWNER=$(OWNER)"
	@echo "PROJECT_NAME=$(PROJECT_NAME)"
	@echo "FULL_BRANCH=$(FULL_BRANCH)"
	@echo "BRANCH=$(BRANCH)"
	@echo "TAG=$(TAG)"
	@echo "CONTAINER=$(CONTAINER)"
	@echo "REMOTE_URL=$(REMOTE_URL)"
	@echo ""
	@echo "=== Aider Config ==="
	@echo "WORK_DIR=$(WORK_DIR)"
	@echo "AIDER_TAG=$(AIDER_TAG)"
	@echo "AIDER_MODEL=$(AIDER_MODEL)"
	@echo "AIDER_FLAGS=$(AIDER_FLAGS)"
	@echo "DOCKER_ENV_FLAGS=$(DOCKER_ENV_FLAGS)"
	@echo ""

# ============================================================
# 7. Git-flow-next release/hotfix
# ============================================================

require_gitflow_next:
	@if ! git flow version 2>/dev/null | grep -q 'git-flow-next'; then \
		echo "Error: git-flow-next required (Go rewrite). Install: brew install git-flow-next"; \
		exit 1; \
	fi

minor_release: require_gitflow_next
	# Start a minor release with incremented minor version
	git flow release start $$(git tag --sort=-v:refname | sed 's/^v//' | head -n 1 | awk -F'.' '{print $$1"."$$2+1".0"}') && echo "or use 'make release_finish' to finish the release"

patch_release: require_gitflow_next
	# Start a patch release with incremented patch version
	git flow release start $$(git tag --sort=-v:refname | sed 's/^v//' | head -n 1 | awk -F'.' '{print $$1"."$$2"."$$3+1}') && echo "or use 'make release_finish' to finish the release"

major_release: require_gitflow_next
	# Start a major release with incremented major version
	git flow release start $$(git tag --sort=-v:refname | sed 's/^v//' | head -n 1 | awk -F'.' '{print $$1+1".0.0"}') && echo "or use 'make release_finish' to finish the release"

hotfix: require_gitflow_next
	# Start a hotfix with incremented n.n.n.n version (incrementing the fourth number)
	git flow hotfix start $$(git tag --sort=-v:refname | sed 's/^v//' | head -n 1 | awk -F'.' '{print $$1"."$$2"."$$3"."$$4+1}') && echo "or use 'make hotfix_finish' to finish the hotfix"

release_finish: require_gitflow_next
	git flow release finish && git push origin develop && git push origin master && git push --tags && git checkout develop

hotfix_finish: require_gitflow_next
	git flow hotfix finish && git push origin develop && git push origin master && git push --tags && git checkout master

# ============================================================
# 8. things_clean
# ============================================================
things_clean:
	git clean --exclude='!.env*' -Xdf

# ============================================================
# 9. .PHONY
# ============================================================
.PHONY: help show_vars require_gitflow_next \
	minor_release patch_release major_release hotfix \
	release_finish hotfix_finish things_clean \
	aider aider_full aider_ollama aider_groq aider_openrouter \
	aider_pull aider_build aider_run_custom \
	it_stop it_clean it_gone
