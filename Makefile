generate:
	@echo "Generating Swift files 🏭"

	@rm -rf Sources/OTLPCore/Generated
	@mkdir Sources/OTLPCore/Generated
	@cd opentelemetry-proto && protoc \
		--swift_opt=Visibility=Public \
		--swift_out=../Sources/OTLPCore/Generated \
		opentelemetry/proto/common/v1/common.proto \
		opentelemetry/proto/resource/v1/resource.proto \
		opentelemetry/proto/trace/v1/trace.proto
	@echo "Generated shared Swift files 🏭"

	@rm -rf Sources/OTLPGRPC/Generated
	@mkdir Sources/OTLPGRPC/Generated
	@cd opentelemetry-proto && protoc \
		--swift_out=../Sources/OTLPGRPC/Generated \
		--swift_opt=ProtoPathModuleMappings=../module-mapping.proto \
		--grpc-swift_out=Client=true,Server=false:../Sources/OTLPGRPC/Generated \
		opentelemetry/proto/collector/trace/v1/trace_service.proto
	@echo "Generated OTLPGRPC Swift files 🏭"

.PHONY: generate
