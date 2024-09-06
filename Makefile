SEVERITIES = HIGH,CRITICAL

BUILD_META=-build$(shell date +%Y%m%d)
PKG ?= github.com/kubernetes/autoscaler
SRC ?= github.com/kubernetes/autoscaler
TAG ?= ${GITHUB_ACTION_TAG}
export DOCKER_BUILDKIT?=1

ifeq ($(TAG),)
TAG := 1.8.20$(BUILD_META)
endif

REPO ?= rancher
IMAGE = $(REPO)/hardened-addon-resizer:$(TAG)
TARGET_PLATFORMS ?= linux/amd64,linux/arm64

.PHONY: push-image
push-image:
	docker buildx build \
		--sbom=true \
		--attest type=provenance,mode=max \
		--platform=$(TARGET_PLATFORMS) \
		--build-arg PKG=$(PKG) \
		--build-arg SRC=$(SRC) \
		--build-arg TAG=$(TAG:$(BUILD_META)=) \
		--tag "$(IMAGE)" \
		--push \
		.

.PHONY: log
log:
	@echo "IMAGE=$(IMAGE)"
	@echo "TAG=$(TAG:$(BUILD_META)=)"
	@echo "PKG=$(PKG)"
	@echo "SRC=$(SRC)"
	@echo "BUILD_META=$(BUILD_META)"
