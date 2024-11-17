FROM golang:alpine AS builder

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod tidy

COPY . . 

RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-linkmode external -extldflags -static" -o app .

FROM scratch

WORKDIR /

COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

COPY --from=builder /app/app .

EXPOSE 8080

RUN adduser -D lnx
USER lnx

CMD ["./app"]

HEALTHCHECK CMD curl --fail http://localhost:8080/ || exit 1
