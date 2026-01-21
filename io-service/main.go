package main

import (
	"net/http"
	"time"
)

func main() {
	http.HandleFunc("/io", func(w http.ResponseWriter, r *http.Request) {
		time.Sleep(1 * time.Second)
		w.Write([]byte("ok"))
	})

	http.ListenAndServe(":8080", nil)
}
