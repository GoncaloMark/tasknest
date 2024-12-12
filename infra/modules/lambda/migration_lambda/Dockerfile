# Stage 1: Build stage
FROM golang:1.23.2-alpine AS builder

RUN apk add --no-cache \
    git \
    gcc \
    musl-dev

WORKDIR /app

COPY go.mod go.sum ./

RUN go mod download

COPY . .

# Build the application
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build \
    -tags lambda \
    -ldflags="-s -w" \
    -o bootstrap main.go

FROM public.ecr.aws/lambda/provided:al2023

COPY --from=builder /app/bootstrap ./bootstrap

ENTRYPOINT [ "./bootstrap" ]