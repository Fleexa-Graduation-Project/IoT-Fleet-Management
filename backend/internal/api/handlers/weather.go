package handlers

import (
	"encoding/json"
	"fmt"
	"log/slog"
	"net/http"
	"os"
	"strconv"
	"sync"
	"time"
)

type weatherCache struct {
	mu        sync.Mutex
	temp      float64
	fetchedAt time.Time
}

// package-level cache — shared across all requests, refreshed every 10 minutes
var weatherState = &weatherCache{temp: 38.0}

func getOutsideTemp() float64 {
	weatherState.mu.Lock()
	defer weatherState.mu.Unlock()

	if !weatherState.fetchedAt.IsZero() && time.Since(weatherState.fetchedAt) < 10*time.Minute {
		return weatherState.temp
	}

	lat, latErr := strconv.ParseFloat(os.Getenv("FLEET_LAT"), 64)
	lon, lonErr := strconv.ParseFloat(os.Getenv("FLEET_LON"), 64)
	if latErr != nil || lonErr != nil || (lat == 0 && lon == 0) {
		return weatherState.temp
	}

	url := fmt.Sprintf(
		"https://api.open-meteo.com/v1/forecast?latitude=%.4f&longitude=%.4f&current=temperature_2m",
		lat, lon,
	)
	client := &http.Client{Timeout: 3 * time.Second}
	resp, err := client.Get(url)
	if err != nil {
		slog.Warn("weather fetch failed, using cached value", "error", err)
		return weatherState.temp
	}
	defer resp.Body.Close()

	var result struct {
		Current struct {
			Temp float64 `json:"temperature_2m"`
		} `json:"current"`
	}
	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		slog.Warn("weather decode failed", "error", err)
		return weatherState.temp
	}

	weatherState.temp = result.Current.Temp
	weatherState.fetchedAt = time.Now()
	return weatherState.temp
}
