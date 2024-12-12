FROM golang:1.23.2-alpine AS builder

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod tidy

COPY . . 

ENV CGO_ENABLED=0 GOOS=linux GOARCH=amd64
RUN go build -o app .

FROM alpine:latest 

RUN apk add --no-cache ca-certificates

WORKDIR /

COPY --from=builder /app/app .

EXPOSE 8080

ENTRYPOINT ["./app"]
