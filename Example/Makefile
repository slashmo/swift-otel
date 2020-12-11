collector:
	docker run \
	--rm \
	-p 13133:13133 \
	-p 14250:14250 \
	-p 14268:14268 \
	-p 55678-55680:55678-55680 \
	-p 6060:6060 \
	-p 7276:7276 \
	-p 8888:8888 \
	-p 9411:9411 \
	-p 9943:9943 \
	-v "${PWD}/config.yaml":/config.yaml \
	--name otelcol \
	otel/opentelemetry-collector --config config.yaml
