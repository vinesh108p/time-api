package main

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"
)

// TestTimeEndpoint tests the GET /time_in_epoch endpoint
func TestTimeInEpochEndpoint(t *testing.T) {
	req, err := http.NewRequest("GET", "/time_in_epoch", nil)
	if err != nil {
		t.Fatalf("Unable to create the request: %v", err)
	}

	rr := httptest.NewRecorder()
	handler := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		currentTime := time.Now().Unix()
		response := map[string]int64{"The current epoch time": currentTime}
		jsonResponse, err := json.Marshal(response)
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		w.Write(jsonResponse)
	})

	handler.ServeHTTP(rr, req)

	// Check the status code is 200
	if status := rr.Code; status != http.StatusOK {
		t.Errorf("Response code is not OK: got %v want %v",
			status, http.StatusOK)
	}

	// Check the Content-Type header for JSON
	if contentType := rr.Header().Get("Content-Type"); contentType != "application/json" {
		t.Errorf("Response has an incorrect content type: got %v want %v",
			contentType, "application/json")
	}

	// Check the response body is valid per API schema.
	var response map[string]int64
	if err := json.Unmarshal(rr.Body.Bytes(), &response); err != nil {
		t.Fatalf("Response cannot be parsed, should be a JSON response: %v", err)
	}

	currentTime := time.Now().Unix()
	if epochTime, ok := response["The current epoch time"]; !ok {
		t.Errorf("Response does not have 'The current epoch time' as a JSON key")
	} else if epochTime > currentTime || epochTime < currentTime-1 {
		t.Errorf("Response does not have the correct time: got %v want between %v and %v",
			epochTime, currentTime-1, currentTime)
	}
}
