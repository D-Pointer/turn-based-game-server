#########################################################################################
# Build image that compiles Vapor and the server
#########################################################################################
FROM swift:4.1 as builder
WORKDIR /app

# create a dire where everything related to Swift is copied
RUN mkdir -p /build/lib && cp -R /usr/lib/swift/linux/*.so /build/lib


ADD Sources /app/Sources
ADD Package.swift /app/

RUN swift build -c release && mv `swift build -c debug --show-bin-path`/turn-based-server /app
#RUN swift build -c release && mv `swift build -c release --show-bin-path`/turn-based-server /app

RUN ldd /app/turn-based-server

#########################################################################################
# Deployment image
#########################################################################################
FROM ubuntu:16.04

RUN apt-get -qq update && \ 
    apt-get install -y apt-utils && \
    apt-get install -y libssl1.0.0 libatomic1 libxml2 libbsd0 tzdate libcurl3 && \
    rm -r /var/lib/apt/lists/*

WORKDIR /app

COPY --from=builder /app/turn-based-server .
COPY --from=builder /build/lib/* /usr/lib/

RUN ldd /app/turn-based-server

EXPOSE 8080

CMD ["/app/turn-based-server", "serve"]
#CMD ["/app/turn-based-server", "serve", "--bind", "0.0.0.0"]

