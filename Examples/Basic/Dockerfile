FROM swift:5.3-focal as build

WORKDIR /build

COPY . .

WORKDIR /build/Examples/Basic

RUN swift package resolve
RUN swift build -c release

WORKDIR /staging

RUN cp "$(swift build --package-path /build/Examples/Basic -c release --show-bin-path)/Run" ./

FROM swift:5.3-focal-slim

RUN useradd --user-group --create-home --system --skel /dev/null --home-dir /app example

WORKDIR /app

COPY --from=build --chown=example:example /staging /app

USER example:example

ENTRYPOINT [ "./Run" ]
CMD ["serve", "--env", "production", "--hostname", "0.0.0.0", "--port", "8080"]
