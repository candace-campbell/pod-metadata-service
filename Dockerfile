FROM golang:1.25-alpine AS builder

WORKDIR /app

COPY app/ .

RUN go mod download
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o pod-metadata


FROM scratch

COPY --from=builder /app/pod-metadata pod-metadata

EXPOSE 8081
CMD ["./pod-metadata"]