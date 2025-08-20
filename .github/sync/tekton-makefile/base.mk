###################################################
### WARNING: This file is synced from AlaudaDevops/tektoncd-operator
### DO NOT CHANGE IT MANUALLY
###################################################
TOOLBIN ?= $(shell pwd)/bin

# Get the currently used golang install path (in GOPATH/bin, unless GOBIN is set)
ifeq (,$(shell go env GOBIN))
GOBIN=$(shell go env GOPATH)/bin
else
GOBIN=$(shell go env GOBIN)
endif

# SUFFIX is the suffix of the version, usually it is the short commit hash
SUFFIX ?=
# If SUFFIX is not empty and does not contain a dash, add a dash prefix
SUFFIX := $(if $(and $(SUFFIX),$(filter-out -%, $(SUFFIX))),-$(SUFFIX),$(SUFFIX))
# NEW_COMPONENT_VERSION is the new version of the component
NEW_COMPONENT_VERSION ?= $(VERSION)$(SUFFIX)

ARCH ?= amd64
GITNAME = $(shell git config --get user.name | sed 's/ //g')

# Setting SHELL to bash allows bash commands to be executed by recipes.
# This is a requirement for 'setup-envtest.sh' in the test target.
# Options are set to exit when a recipe line exits non-zero or a piped command fails.
SHELL = /usr/bin/env bash -o pipefail
.SHELLFLAGS = -ec

.PHONY: all-default
all-default: help-default

HELP_FUN = \
	%help; while(<>){push@{$$help{$$2//'options'}},[$$1,$$3] \
	if/^([\w-_]+)\s*:.*\#\#(?:@(\w+))?\s(.*)$$/}; \
	print"\033[1m$$_:\033[0m\n", map"  \033[36m$$_->[0]\033[0m".(" "x(20-length($$_->[0])))."$$_->[1]\n",\
	@{$$help{$$_}},"\n" for keys %help; \

.PHONY: help-default
help-default: ##@General Show this help
	@echo -e "Usage: make \033[36m<target>\033[0m\n"
	@perl -e '$(HELP_FUN)' $(MAKEFILE_LIST)

YQ_VERSION ?= v4.43.1
YQ ?= $(TOOLBIN)/yq-$(YQ_VERSION)
.PHONY: yq
yq: ##@Setup Download yq locally if necessary.
	$(call go-install-tool,$(YQ),github.com/mikefarah/yq/v4,$(YQ_VERSION))

.PHONY: download-release-yaml-default
download-release-yaml-default: yq ##@Development Download the release yaml
	@# Download the release.yaml
	$(call download-file,$(RELEASE_YAML),$(RELEASE_YAML_PATH))
	@# Format the YAML for easier image replacement later
	$(YQ) eval -P -i $(RELEASE_YAML_PATH)

.PHONY: update-component-version-default
update-component-version-default: yq ##@Development Update the component version
	@echo "Update the version to $(NEW_COMPONENT_VERSION)"
	$(YQ) eval '.global.version = "$(NEW_COMPONENT_VERSION)"' -i values.yaml
	$(YQ) eval "(select(.kind == \"ConfigMap\" and .metadata.name == \"$(VERSION_CONFIGMAP_NAME)\") | .data.version) = \"$(NEW_COMPONENT_VERSION)\"" -i $(RELEASE_YAML_PATH)

CONTROLLER_TOOLS_VERSION ?= v0.17.1
CONTROLLER_GEN ?= $(TOOLBIN)/controller-gen-$(CONTROLLER_TOOLS_VERSION)
.PHONY: controller-gen
controller-gen: ##@Setup Download controller-gen locally if necessary.
	$(call go-install-tool,$(CONTROLLER_GEN),sigs.k8s.io/controller-tools/cmd/controller-gen,$(CONTROLLER_TOOLS_VERSION))

.PHONY: generate-crd-docs-default
generate-crd-docs-default: controller-gen ##@Development Generate CRD for docs/shared/crds.
	$(CONTROLLER_GEN) crd:allowDangerousTypes=true paths=./upstream/pkg/apis/... output:crd:artifacts:config=docs/shared/crds

.PHONY: save-new-patch-default
save-new-patch-default: ##@Patch 将upstream(submodule)的变更保存为patch文件并清空变更
	@mkdir -p .tekton/patches
	@cd upstream && git add --all
	@cd upstream && git diff --cached > ../.tekton/patches/new.patch
	@make clean-patches-default

.PHONY: apply-patches-default
# PATCHES: 指定要应用的patch文件列表，多个文件用空格分隔。例如：PATCHES="patch1.yaml patch2.yaml"
# 如果不指定，则应用所有patch文件
PATCHES ?= $(wildcard .tekton/patches/*.patch)
apply-patches-default: ##@Patch 将patches应用到upstream子模块，可通过PATCHES指定具体文件
	@# 可以给 git apply 指定 --reject 选项可以将无法应用的补丁保存为 .rej 文件
	@cd upstream && \
    set -e; \
	for patch in $(PATCHES); do \
		if [ -f "../$$patch" ]; then \
			echo "Applying $$patch ..."; \
			git apply "../$$patch"; \
		else \
			echo "Warning: Patch file $$patch not found"; \
		fi \
	done

.PHONY: upgrade-go-dependencies-default
upgrade-go-dependencies-default: ##@Development Upgrade go dependencies to fix vulnerabilities
	@cd upstream && \
		if [ -d "vendor" ]; then \
			if git diff --quiet vendor/; then \
				echo "No changes in vendor directory"; \
			else \
				git diff vendor/ | cat; \
				echo -e "\033[31mWarning: There are uncommitted changes in [./upstream/vendor] directory that will be overwritten!\033[0m"; \
				exit 1; \
			fi; \
		fi && \
		for script in ../.tekton/patches/[0-9]*.sh; do \
			if [ -f "$$script" ]; then \
				echo "Executing $$(basename "$$script")..."; \
				bash -x "$$script" || { echo "Failed to execute $$script"; exit 1; }; \
			fi; \
		done

.PHONY: clean-patches-default
clean-patches-default: ##@Patch 清理patch对upstream的变更
	@cd upstream && git reset --hard HEAD
	@cd upstream && git clean -fd
	@# This command initializes and updates the "upstream" Git submodule recursively.
	@git submodule update --init --recursive upstream

.PHONY: deploy-defauilt
deploy-default:
	cat release/release.yaml | sed "s/build-harbor.alauda.cn/registry.alauda.cn:60070/g" | kubectl apply -f -

.PHONY: undeploy-default
undeploy-default:
	cat release/release.yaml | kubectl delete -f -

KUSTOMIZE_VERSION ?= v5.3.0
KUSTOMIZE ?= $(TOOLBIN)/kustomize-$(KUSTOMIZE_VERSION)
kustomize: ##@Setup Download kustomize locally if necessary.
	$(call go-install-tool,$(KUSTOMIZE),sigs.k8s.io/kustomize/kustomize/v5,$(KUSTOMIZE_VERSION))

VULNCHECK_DB ?= https://vuln.go.dev
VULNCHECK_MODE ?= source
VULNCHECK_DIR ?= upstream
VULNCHECK_PATH ?= ./...
VULNCHECK_OUTPUT ?= vulncheck.txt
vulncheck: govulncheck ##@Development Run govulncheck against code. Check base.mk file for available envvars
	$(GOVULNCHECK) -db=$(VULNCHECK_DB) -mode=$(VULNCHECK_MODE) -C $(VULNCHECK_DIR) $(VULNCHECK_PATH) | tee $(VULNCHECK_OUTPUT)

GOVULNCHECK_VERSION ?= master
GOVULNCHECK ?= $(TOOLBIN)/govulncheck-$(GOVULNCHECK_VERSION)
govulncheck: ##@Setup Download govulncheck locally if necessary.
# using master until 1.0.5 is released, https://github.com/golang/go/issues/66139
	$(call go-install-tool,$(GOVULNCHECK),golang.org/x/vuln/cmd/govulncheck,$(GOVULNCHECK_VERSION))

# go-install-tool will 'go install' any package with custom target and name of binary, if it doesn't exist
# $1 - target path with name of binary (ideally with version)
# $2 - package url which can be installed
# $3 - specific version of package
define go-install-tool
@[ -f $(1) ] || { \
set -e; \
package=$(2)@$(3) ;\
echo "Downloading $${package} into $(TOOLBIN) as $(1)" ;\
GOBIN=$(TOOLBIN) go install $${package} ;\
mv "$$(echo "$(1)" | sed "s/-$(3)$$//")" $(1) ;\
}
endef

# download-file will download file from url and save to target path
# $1 - url to download the file
# $2 - target path to save the file
define download-file
@{ \
set -e; \
echo "Downloading file from $(1) into $(2)" ;\
curl -sSL $(1) --create-dirs -o $(2) ;\
}
endef

%: %-default
	@ true
