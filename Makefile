# If no target is specified, display help
.DEFAULT_GOAL := help

.PHONY: help
help:  # Display this help.
	@-+echo "Run make with one of the following targets:"
	@-+echo
	@-+grep -Eh "^[a-z-]+:.*#" $(abspath $(lastword $(MAKEFILE_LIST))) | sed -E 's/^(.*:)(.*#+)(.*)/  \1 @@@ \3 /' | column -t -s "@@@"

.PHONY: all
all: build examples  # Build swift-otel and example packages.

# Building OTel package
# -----------------------------------------------------------------------------
.PHONY: build
build:  # Build swift-otel package.
	swift build

.PHONY: test
test:  # Run tests for swift-otel package.
	swift test

# Building examples
# -----------------------------------------------------------------------------
EXAMPLES_DIR = Examples
EXAMPLES = $(shell find "$(EXAMPLES_DIR)" -maxdepth 2 -name Package.swift -print0 | xargs -0 dirname)

.PHONY: $(EXAMPLES_DIR)/%.build
$(EXAMPLES_DIR)/%.build:
	swift build --package-path "$(basename $@)"

.PHONY: examples
examples: $(patsubst %,%.build,$(EXAMPLES))  # Build example packages.

# Download protoc plugins
# -----------------------------------------------------------------------------
GRPC_SWIFT_VERSION = 1.21.0
PROTOC_GRPC_SWIFT_PLUGINS_SHA256SUM = d5316b166b7e9bbb79e1aec4e00f14e523c99d406d39009aeb7d423f4bd3b2ca
PROTOC_GRPC_SWIFT_PLUGINS_DOWNLOAD_CACHE_DIR = .protoc-grpc-swift-plugins.download
PROTOC_GRPC_SWIFT_PLUGINS_URL = https://github.com/grpc/grpc-swift/releases/download/$(GRPC_SWIFT_VERSION)/protoc-grpc-swift-plugins-$(GRPC_SWIFT_VERSION).zip
PROTOC_GRPC_SWIFT_PLUGINS_ZIP = $(PROTOC_GRPC_SWIFT_PLUGINS_DOWNLOAD_CACHE_DIR)/$(notdir $(PROTOC_GRPC_SWIFT_PLUGINS_URL))
PROTOC_GRPC_SWIFT_PLUGINS_ROOT ?= .protoc-grpc-swift-plugins
PROTOC_GEN_SWIFT ?= $(PROTOC_GRPC_SWIFT_PLUGINS_ROOT)/bin/protoc-gen-swift
PROTOC_GEN_GRPC_SWIFT ?= $(PROTOC_GRPC_SWIFT_PLUGINS_ROOT)/bin/protoc-gen-grpc-swift

$(PROTOC_GRPC_SWIFT_PLUGINS_ZIP):
	curl -L --create-dirs -o $@ $(PROTOC_GRPC_SWIFT_PLUGINS_URL)
	echo "$(PROTOC_GRPC_SWIFT_PLUGINS_SHA256SUM) $@" | sha256sum --check

$(PROTOC_GRPC_SWIFT_PLUGINS_ROOT): $(PROTOC_GRPC_SWIFT_PLUGINS_ZIP)
	unzip -o -d $@ $<
	test -x $(PROTOC_GEN_SWIFT)
	test -x $(PROTOC_GEN_GRPC_SWIFT)
	touch $(PROTOC_GEN_SWIFT) $(PROTOC_GEN_GRPC_SWIFT)

$(PROTOC_GEN_SWIFT) $(PROTOC_GEN_GRPC_SWIFT): $(PROTOC_GRPC_SWIFT_PLUGINS_ROOT)

.PHONY: download-protoc-plugins
download-protoc-plugins: $(PROTOC_GEN_SWIFT) $(PROTOC_GEN_GRPC_SWIFT)

.PHONY: clean-download-cache
clean-download-cache:
	-rm -rf $(PROTOC_GRPC_SWIFT_PLUGINS_DOWNLOAD_CACHE_DIR)

# Code generation
# -----------------------------------------------------------------------------
PROTO_ROOT = opentelemetry-proto
PROTO_MODULEMAP = module-mapping.proto

OTLP_CORE_SWIFT_ROOT = Sources/OTLPCore/Generated
OTLP_CLIENT_GRPC_SWIFT_ROOT = Sources/OTLPGRPC/Generated
OTLP_SERVER_GRPC_SWIFT_ROOT = Tests/OTLPGRPCTests/Generated

OTLP_CORE_PROTOS += $(PROTO_ROOT)/opentelemetry/proto/common/v1/common.proto
OTLP_CORE_PROTOS += $(PROTO_ROOT)/opentelemetry/proto/resource/v1/resource.proto
OTLP_CORE_PROTOS += $(PROTO_ROOT)/opentelemetry/proto/logs/v1/logs.proto
OTLP_CORE_PROTOS += $(PROTO_ROOT)/opentelemetry/proto/metrics/v1/metrics.proto
OTLP_CORE_PROTOS += $(PROTO_ROOT)/opentelemetry/proto/trace/v1/trace.proto

OTLP_GRPC_PROTOS += $(PROTO_ROOT)/opentelemetry/proto/collector/logs/v1/logs_service.proto
OTLP_GRPC_PROTOS += $(PROTO_ROOT)/opentelemetry/proto/collector/metrics/v1/metrics_service.proto
OTLP_GRPC_PROTOS += $(PROTO_ROOT)/opentelemetry/proto/collector/trace/v1/trace_service.proto

OTLP_CORE_SWIFTS = $(patsubst  $(PROTO_ROOT)/%.proto,$(OTLP_CORE_SWIFT_ROOT)/%.pb.swift,$(OTLP_CORE_PROTOS))

OTLP_CLIENT_GRPC_SWIFTS = $(subst $(PROTO_ROOT),$(OTLP_CLIENT_GRPC_SWIFT_ROOT),$(OTLP_GRPC_PROTOS:.proto=.pb.swift) $(OTLP_GRPC_PROTOS:.proto=.grpc.swift))
OTLP_SERVER_GRPC_SWIFTS = $(subst $(PROTO_ROOT),$(OTLP_SERVER_GRPC_SWIFT_ROOT),$(OTLP_GRPC_PROTOS:.proto=.pb.swift) $(OTLP_GRPC_PROTOS:.proto=.grpc.swift))

$(OTLP_CORE_SWIFTS): $(OTLP_CORE_PROTOS) $(PROTO_MODULEMAP) $(PROTOC_GEN_SWIFT)
	@mkdir -pv $(OTLP_CORE_SWIFT_ROOT)
	protoc $(OTLP_CORE_PROTOS) \
		--proto_path=$(PROTO_ROOT) \
		--plugin=$(PROTOC_GEN_SWIFT) \
		--swift_out=$(OTLP_CORE_SWIFT_ROOT) \
		--swift_opt=Visibility=Public \
		--experimental_allow_proto3_optional \

$(OTLP_CLIENT_GRPC_SWIFTS): $(OTLP_GRPC_PROTOS) $(PROTO_MODULEMAP) $(PROTOC_GEN_GRPC_SWIFT)
	@mkdir -pv $(OTLP_CLIENT_GRPC_SWIFT_ROOT)
	protoc $(OTLP_GRPC_PROTOS) \
		--proto_path=$(PROTO_ROOT) \
		--plugin=$(PROTOC_GEN_GRPC_SWIFT) \
		--swift_out=$(OTLP_CLIENT_GRPC_SWIFT_ROOT) \
		--swift_opt=ProtoPathModuleMappings=$(PROTO_MODULEMAP) \
		--grpc-swift_out=Client=true,Server=false:$(OTLP_CLIENT_GRPC_SWIFT_ROOT) \

$(OTLP_SERVER_GRPC_SWIFTS): $(OTLP_GRPC_PROTOS) $(PROTO_MODULEMAP) $(PROTOC_GEN_GRPC_SWIFT)
	@mkdir -pv $(OTLP_SERVER_GRPC_SWIFT_ROOT)
	protoc $(OTLP_GRPC_PROTOS) \
		--proto_path=$(PROTO_ROOT) \
		--plugin=$(PROTOC_GEN_GRPC_SWIFT) \
		--swift_out=$(OTLP_SERVER_GRPC_SWIFT_ROOT) \
		--swift_opt=ProtoPathModuleMappings=$(PROTO_MODULEMAP) \
		--grpc-swift_out=Client=false,Server=true:$(OTLP_SERVER_GRPC_SWIFT_ROOT) \

.PHONY: generate
generate: $(OTLP_CORE_SWIFTS) $(OTLP_CLIENT_GRPC_SWIFTS) $(OTLP_SERVER_GRPC_SWIFTS)  # Generate Swift files from Protobuf.

.PHONY: delete-generated-code
delete-generated-code:  # Delete all pb.swift and .grpc.swift files.
	@read -p "Delete all *.pb.swift and *.grpc.swift files in Sources/? [y/N]" ans && [ $${ans:-N} = y ]
	find Sources -name *.pb.swift -delete -o -name *.grpc.swift -delete

# Xcode workspace with examples
# -----------------------------------------------------------------------------
WORKSPACE = swift-otel-workspace.xcworkspace
WORKSPACE_CONTENTS = $(WORKSPACE)/contents.xcworkspacedata

workspace: $(WORKSPACE_CONTENTS)  # Generate and open Xcode workspace including examples.
	open $(WORKSPACE)

define contents_xcworkspacedata
<?xml version="1.0" encoding="UTF-8"?>
<Workspace version="1.0">
	<Group location="container:" name="swift-otel">
		<FileRef location="group:." name="swift-otel"></FileRef>
	</Group>
	<Group location="container:" name="Examples">
	$(foreach example,$(EXAMPLES),<FileRef location="group:$(example)"></FileRef>\n)
	</Group>
	<Group location="container:Benchmarks" name="Benchmarks">
		<FileRef location="group:." name="benchmarks"></FileRef>
	</Group>
</Workspace>
endef
export contents_xcworkspacedata

$(WORKSPACE_CONTENTS): Makefile
	rm -rf $(WORKSPACE)
	mkdir -p $(dir $@)
	echo "$$contents_xcworkspacedata" > $@

.DELETE_ON_ERROR:
