SEVERITIES = HIGH,CRITICAL

UNAME_M = $(shell uname -m)
ARCH=
ifeq ($(UNAME_M), x86_64)
	ARCH=amd64
else ifeq ($(UNAME_M), aarch64)
	ARCH=arm64
else 
	ARCH=$(UNAME_M)
endif

BUILD_META=-build$(shell date +%Y%m%d)
ORG ?= rancher
PKG ?= github.com/kubernetes/autoscaler
SRC ?= github.com/kubernetes/autoscaler
TAG ?= 1.8.20$(BUILD_META)

ifeq (,$(filter %$(BUILD_META),$(TAG)))
$(error TAG ${TAG} needs to end with build metadata: $(BUILD_META))
endif

.PHONY: image-build
image-build:
	docker build \
		--pull \
		--platform=$(ARCH) \
		--build-arg ARCH=$(ARCH) \
		--build-arg PKG=$(PKG) \
		--build-arg SRC=$(SRC) \
		--build-arg TAG=$(TAG:$(BUILD_META)=) \
		--tag $(ORG)/hardened-addon-resizer:$(TAG) \
		--tag $(ORG)/hardened-addon-resizer:$(TAG)-$(ARCH) \
		.

.PHONY: log
log:
	@echo "ARCH=$(ARCH)"
	@echo "TAG=$(TAG)"
	@echo "ORG=$(ORG)"
	@echo "PKG=$(PKG)"
	@echo "SRC=$(SRC)"
	@echo "BUILD_META=$(BUILD_META)"
	@echo "UNAME_M=$(UNAME_M)"

