#ARG BCI_IMAGE=registry.suse.com/bci/bci-busybox
ARG GO_IMAGE=rancher/hardened-build-base:v1.20.14b1

#FROM ${BCI_IMAGE} as bci
# Image that provides cross compilation tooling.
FROM --platform=$BUILDPLATFORM rancher/mirrored-tonistiigi-xx:1.3.0 as xx
FROM --platform=$BUILDPLATFORM ${GO_IMAGE} as base-builder
# copy xx scripts to your build stage
COPY --from=xx / /
RUN set -x && \
    apk --no-cache add file make git clang lld
RUN xx-apk --no-cache add musl-dev gcc lld
ARG TARGETPLATFORM

FROM --platform=$BUILDPLATFORM base-builder as addon-builder
ARG ARCH
ARG SRC=github.com/kubernetes/autoscaler
ARG PKG=github.com/kubernetes/autoscaler
RUN git clone https://${SRC}.git $GOPATH/src/${PKG}
ARG TAG=1.8.20
WORKDIR $GOPATH/src/${PKG}/addon-resizer
RUN git branch -a
RUN git checkout addon-resizer-${TAG} -b ${TAG}
RUN go mod download

# cross-compilation setup
ARG TARGETPLATFORM
RUN xx-go --wrap && \
    GOARCH=${ARCH} GO_LDFLAGS="-linkmode=external -X ${PKG}/pkg/version.VERSION=${TAG}" \
    go-build-static.sh -gcflags=-trimpath=${GOPATH}/src -o pod_nanny nanny/main/pod_nanny.go
RUN go-assert-static.sh pod_nanny
RUN xx-verify --static pod_nanny
RUN if [ "${ARCH}" = "amd64" ]; then \
        go-assert-boring.sh pod_nanny; \
    fi
RUN install pod_nanny /usr/local/bin/

FROM ${GO_IMAGE} as strip_binary
#strip needs to run on TARGETPLATFORM, not BUILDPLATFORM
COPY --from=addon-builder /usr/local/bin/pod_nanny /pod_nanny
RUN strip /pod_nanny

FROM scratch
COPY --from=strip_binary /pod_nanny /pod_nanny
ENTRYPOINT ["/pod_nanny"]
