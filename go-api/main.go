package main

import (
	"io"
	"net/http"
	"time"
)

var client = &http.Client{
	Timeout: 2 * time.Second,
}

func handler(w http.ResponseWriter, r *http.Request) {
	resp, err := client.Get("http://io-service:8080/io")
	if err != nil {
		http.Error(w, err.Error(), 500)
		return
	}
	defer resp.Body.Close()

	body, _ := io.ReadAll(resp.Body)
	w.Write(body)
}

func main() {
	http.HandleFunc("/call", handler)
	http.ListenAndServe(":8081", nil)
}
