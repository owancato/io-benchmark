FROM golang:1.22-alpine

WORKDIR /app
COPY go.mod .
COPY main.go .
RUN go build -o go-api

EXPOSE 8081
CMD ["./go-api"]
