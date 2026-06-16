package models

import (
	"fmt"
	"strconv"
	"time"
)

// EpochTime stores a Unix timestamp as int64 in DynamoDB but serializes
// to a human-readable "2006-01-02 15:04" string in JSON API responses.
type EpochTime int64

const epochTimeFormat = "2006-01-02 15:04"

// MarshalJSON renders the epoch as "YYYY-MM-DD HH:MM" (UTC).
func (e EpochTime) MarshalJSON() ([]byte, error) {
	if e == 0 {
		return []byte(`"N/A"`), nil
	}
	formatted := time.Unix(int64(e), 0).UTC().Format(epochTimeFormat)
	return []byte(`"` + formatted + `"`), nil
}

// UnmarshalJSON accepts both a quoted date string and a raw number so the
// type round-trips cleanly and Lambda inbound payloads (epoch ints) still work.
func (e *EpochTime) UnmarshalJSON(data []byte) error {
	s := string(data)
	// Strip surrounding quotes if present
	if len(s) >= 2 && s[0] == '"' {
		s = s[1 : len(s)-1]
	}
	// Try parsing as plain integer first (inbound epoch)
	if n, err := strconv.ParseInt(s, 10, 64); err == nil {
		*e = EpochTime(n)
		return nil
	}
	// Try parsing as formatted date string (round-trip)
	t, err := time.ParseInLocation(epochTimeFormat, s, time.UTC)
	if err != nil {
		return fmt.Errorf("EpochTime: cannot parse %q as epoch int or %q layout", s, epochTimeFormat)
	}
	*e = EpochTime(t.Unix())
	return nil
}

// Int64 returns the raw Unix timestamp for internal logic that still needs the number.
func (e EpochTime) Int64() int64 {
	return int64(e)
}
