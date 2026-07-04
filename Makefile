## ------------------------------------------------------------
## BlanketOps Environments – Install Makefile
##
## INSTALL-ONLY REPOSITORY
## - No Go
## - No codegen
## - No tests
## - No image builds
## ------------------------------------------------------------

SHELL := /usr/bin/env bash
.SHELLFLAGS := -ec

##@ Tools

LOCALBIN ?= $(shell pwd)/bin

OS := $(shell uname | tr '[:upper:]' '[:lower:]')
ARCH := $(shell uname -m)

ifeq ($(ARCH),x86_64)
  ARCH = amd64
endif
ifeq ($(ARCH),aarch64)
  ARCH = arm64
endif

KUBECTL ?= kubectl
KUSTOMIZE := $(LOCALBIN)/kustomize
KUSTOMIZE_VERSION ?= v5.7.1

$(LOCALBIN):
	mkdir -p "$(LOCALBIN)"

.PHONY: kustomize
kustomize: $(KUSTOMIZE)

$(KUSTOMIZE): $(LOCALBIN)
	@echo "Downloading kustomize $(KUSTOMIZE_VERSION)"
	curl -sSL \
	  https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2F$(KUSTOMIZE_VERSION)/kustomize_$(KUSTOMIZE_VERSION)_$(OS)_$(ARCH).tar.gz \
	| tar -xz -C $(LOCALBIN)
	@chmod +x $(KUSTOMIZE)

.PHONY: check-tools
check-tools: kustomize ## Verify required tools are available
	@command -v $(KUBECTL) >/dev/null 2>&1 || { echo "kubectl not found"; exit 1; }

##@ General

.PHONY: help
help: ## Show available make targets
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} \
	/^[a-zA-Z_-]+:.*##/ { printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2 }' \
	$(MAKEFILE_LIST)

##@ Build

.PHONY: build
build: check-tools ## Render all install manifests to stdout
	$(KUSTOMIZE) build config/default

.PHONY: build-crds
build-crds: check-tools ## Render CRDs only
	$(KUSTOMIZE) build config/crd

.PHONY: build-installer
build-installer: check-tools ## Generate a single consolidated install.yaml
	@mkdir -p dist
	$(KUSTOMIZE) build config/default > dist/install.yaml
	@echo "✔ dist/install.yaml generated"

##@ Deployment

ifndef ignore-not-found
ignore-not-found = false
endif

.PHONY: install
install: check-tools ## Install CRDs only
	$(KUSTOMIZE) build config/crd | $(KUBECTL) apply -f -

.PHONY: uninstall
uninstall: check-tools ## Uninstall CRDs
	$(KUSTOMIZE) build config/crd | $(KUBECTL) delete --ignore-not-found=$(ignore-not-found) -f -

.PHONY: deploy
deploy: check-tools ## Deploy BlanketOps Environments
	$(KUSTOMIZE) build config/default | $(KUBECTL) apply -f -

.PHONY: undeploy
undeploy: check-tools ## Remove BlanketOps Environments
	$(KUSTOMIZE) build config/default | $(KUBECTL) delete --ignore-not-found=$(ignore-not-found) -f -

##@ Maintenance

.PHONY: sync-rbac
sync-rbac: ## Sync RBAC manifests from the controller repo
	@echo "Syncing RBAC from blanketops-environments-controller..."
	@# Replace the path below with the actual relative path to your controller repo
	cp ../blanketops-environments-controller/config/rbac/role.yaml config/rbac/role.yaml
	@echo "✔ RBAC synced"
	
##@ Verification

.PHONY: diff
diff: check-tools ## Show diff against live cluster
	$(KUSTOMIZE) build config/default | $(KUBECTL) diff -f - || true

.PHONY: validate
validate: check-tools ## Validate manifests with server-side dry run
	$(KUBECTL) create namespace blanketops-environments-api-system --dry-run=client -o yaml | $(KUBECTL) apply -f -
	$(KUSTOMIZE) build config/default | $(KUBECTL) apply --dry-run=server -f -
