FROM alpine
WORKDIR /app
COPY . .
RUN apk add --no-cache \
        libc6-compat \
        libstdc++
ENTRYPOINT [ "./wrapper.sh" ]
