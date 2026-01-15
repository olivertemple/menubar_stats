package main

import (
	"context"
	"encoding/json"
	"log"
	"net/http"
	"os"
	"os/signal"
	"strconv"
	"strings"
	"syscall"
	"time"

	"github.com/olivertemple/menubar_stats/linux-agent/stats"
)

const (
	defaultPort       = "9955"
	defaultInterval   = "1000"
	defaultLogLevel   = "info"
	agentVersion      = "1.0.0"
)

var (
	collector   *stats.Collector
	bearerToken string
)

type HealthResponse struct {
	OK           bool   `json:"ok"`
	Schema       string `json:"schema"`
	AgentVersion string `json:"agent_version"`
	Hostname     string `json:"hostname"`
}

func main() {
	// Configuration
	port := getEnv("AGENT_PORT", defaultPort)
	intervalMs := getEnv("AGENT_INTERVAL_MS", defaultInterval)
	bearerToken = os.Getenv("AGENT_TOKEN")
	logLevel := getEnv("AGENT_LOG_LEVEL", defaultLogLevel)

	// Parse interval
	intervalMsInt, err := strconv.Atoi(intervalMs)
	if err != nil || intervalMsInt < 100 {
		log.Fatalf("error: invalid AGENT_INTERVAL_MS: %s (must be >= 100)", intervalMs)
	}
	interval := time.Duration(intervalMsInt) * time.Millisecond

	// Configure logging
	if logLevel != "debug" {
		log.SetFlags(log.LstdFlags)
	} else {
		log.SetFlags(log.LstdFlags | log.Lshortfile)
	}

	log.Printf("info: starting MenuBarStats Linux Agent v%s", agentVersion)
	log.Printf("info: config - port: %s, interval: %dms, auth: %v", port, intervalMsInt, bearerToken != "")

	// Initialize collector
	collector = stats.NewCollector(interval)

	// Setup HTTP server
	mux := http.NewServeMux()
	mux.HandleFunc("/v1/health", handleHealth)
	mux.HandleFunc("/v1/stats", authMiddleware(handleStats))

	server := &http.Server{
		Addr:         ":" + port,
		Handler:      mux,
		ReadTimeout:  10 * time.Second,
		WriteTimeout: 10 * time.Second,
		IdleTimeout:  60 * time.Second,
	}

	// Start server
	go func() {
		log.Printf("info: listening on :%s", port)
		if err := server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatalf("error: server failed: %v", err)
		}
	}()

	// Wait for interrupt
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	log.Println("info: shutting down server...")

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	if err := server.Shutdown(ctx); err != nil {
		log.Printf("error: server shutdown failed: %v", err)
	}

	log.Println("info: server stopped")
}

func handleHealth(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	hostname, _ := os.Hostname()
	response := HealthResponse{
		OK:           true,
		Schema:       "v1",
		AgentVersion: agentVersion,
		Hostname:     hostname,
	}

	w.Header().Set("Content-Type", "application/json")
	if err := json.NewEncoder(w).Encode(response); err != nil {
		log.Printf("error: failed to encode health response: %v", err)
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		return
	}
}

func handleStats(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	stats := collector.Collect()

	w.Header().Set("Content-Type", "application/json")
	w.Header().Set("Cache-Control", "no-cache, no-store, must-revalidate")
	
	encoder := json.NewEncoder(w)
	encoder.SetIndent("", "  ")
	if err := encoder.Encode(stats); err != nil {
		log.Printf("error: failed to encode stats: %v", err)
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		return
	}
}

func authMiddleware(next http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		if bearerToken == "" {
			next(w, r)
			return
		}

		authHeader := r.Header.Get("Authorization")
		if authHeader == "" {
			http.Error(w, "Unauthorized", http.StatusUnauthorized)
			return
		}

		parts := strings.SplitN(authHeader, " ", 2)
		if len(parts) != 2 || parts[0] != "Bearer" {
			http.Error(w, "Unauthorized", http.StatusUnauthorized)
			return
		}

		if parts[1] != bearerToken {
			http.Error(w, "Unauthorized", http.StatusUnauthorized)
			return
		}

		next(w, r)
	}
}

func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}
