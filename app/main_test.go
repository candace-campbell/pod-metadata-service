package main

import (
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestHealthz(t *testing.T) {

	req := httptest.NewRequest(http.MethodGet, "/healthz", nil)
	rec := httptest.NewRecorder()

	healthz(rec, req)

	res := rec.Result()
	res.Body.Close()

	if res.StatusCode != http.StatusOK {
		t.Errorf("status = %d, want %d", res.StatusCode, http.StatusOK)
	}

	body := rec.Body.String()
	if body != "ok" {
		t.Errorf("body = %q, want %q", body, "ok")
	}
}

func TestNewMetadata(t *testing.T) {
	got := newMetadata()
	want := Metadata{"localhost", "local", "127.0.0.1", "local-machine"}
	if *got != want {
		t.Errorf("newMetadata() = %+v, want %+v", *got, want)
	}
}

func TestGetPodInfo(t *testing.T) {

	t.Run("uses default when no environment variables are set", func(t *testing.T) {

		t.Setenv("HOSTNAME", "")
		t.Setenv("POD_NAMESPACE", "")
		t.Setenv("POD_IP", "")
		t.Setenv("NODE_NAME", "")

		got := getPodInfo()
		want := Metadata{"localhost", "local", "127.0.0.1", "local-machine"}
		if got != want {
			t.Errorf("getPodInfo() = %+v, want %+v", got, want)
		}
	})

	t.Run("reads environment variables", func(t *testing.T) {

		t.Setenv("HOSTNAME", "test-hostname")
		t.Setenv("POD_NAMESPACE", "test-namespace")
		t.Setenv("POD_IP", "test-ip")
		t.Setenv("NODE_NAME", "test-node")

		got := getPodInfo()
		want := Metadata{"test-hostname", "test-namespace", "test-ip", "test-node"}

		if got != want {
			t.Errorf("getPodInfo() = %+v, want %+v", got, want)
		}
	})
}
