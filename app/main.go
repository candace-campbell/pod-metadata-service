package main

import (
	"encoding/json"
	"log/slog"
	"net/http"
	"os"
)

type Metadata struct {
	Hostname  string `json:"hostname"`
	Namespace string `json:"namespace"`
	Ip        string `json:"ip"`
	Node      string `json:"node"`
}

func main() {
	logger := slog.New(slog.NewTextHandler(os.Stderr, nil))
	slog.SetDefault(logger)

	port := getEnv("PORT", "8081")
	addr := ":" + port

	slog.Info("Starting pod metadata display application")

	http.HandleFunc("/", handler)
	http.HandleFunc("/healthz", healthz)

	slog.Info(addr)

	err := http.ListenAndServe(addr, nil)
	if err != nil {
		slog.Error("Server failed to start", "err", err)
	}

}

func newMetadata() *Metadata {

	return &Metadata{"localhost", "local", "127.0.0.1", "local-machine"}
}

func getPodInfo() Metadata {

	// Start with default values
	defaults := newMetadata()
	metadata := *defaults

	if pod_name := os.Getenv("HOSTNAME"); pod_name != "" {
		metadata.Hostname = pod_name
	}

	if pod_namespace := os.Getenv("POD_NAMESPACE"); pod_namespace != "" {
		metadata.Namespace = pod_namespace
	}

	if pod_ip := os.Getenv("POD_IP"); pod_ip != "" {
		metadata.Ip = pod_ip
	}

	if node_name := os.Getenv("NODE_NAME"); node_name != "" {
		metadata.Node = node_name
	}

	return metadata
}

func handler(w http.ResponseWriter, r *http.Request) {

	slog.Info("Getting pod info")
	info := getPodInfo()
	json.NewEncoder(w).Encode(info)

}

func healthz(w http.ResponseWriter, r *http.Request) {

	w.Write([]byte("ok"))

}

func getEnv(key string, default_key string) string {

	if value := os.Getenv(key); value != "" {
		return value
	}

	return default_key
}
