package models

import (
	"fmt"
	"strconv"
	"time"
)

// EpochTime stores a Unix timestamp as int64 in DynamoDB but serializes
// to a human-readable "2006-01-02 15:04:05" string in JSON API responses.
type EpochTime int64

// epochTimeFormat is the canonical human-readable layout used in API responses.
// Includes seconds so that sub-minute events are distinguishable in the UI.
const epochTimeFormat = "2006-01-02 15:04:05"

// MarshalJSON renders the epoch as "YYYY-MM-DD HH:MM:SS" (UTC).
func (e EpochTime) MarshalJSON() ([]byte, error) {
	if e == 0 {
		return []byte(`"N/A"`), nil
	}
	formatted := time.Unix(int64(e), 0).UTC().Format(epochTimeFormat)
	return []byte(`"` + formatted + `"`), nil
}

// UnmarshalJSON accepts:
//   - a raw integer  (e.g. 1718546400)              — inbound MQTT / DynamoDB epoch
//   - a quoted string in epochTimeFormat             — round-trip from MarshalJSON
//   - a quoted string in the legacy minutes-only fmt — backwards compatibility
func (e *EpochTime) UnmarshalJSON(data []byte) error {
	s := string(data)
	// Strip surrounding quotes if present
	if len(s) >= 2 && s[0] == '"' {
		s = s[1 : len(s)-1]
	}

	// 1. Try parsing as plain integer first (inbound epoch from device / Lambda)
	if n, err := strconv.ParseInt(s, 10, 64); err == nil {
		*e = EpochTime(n)
		return nil
	}

	// 2. Try current format with seconds
	if t, err := time.ParseInLocation(epochTimeFormat, s, time.UTC); err == nil {
		*e = EpochTime(t.Unix())
		return nil
	}

	// 3. Legacy format without seconds (backwards compat for existing DB records)
	legacyFmt := "2006-01-02 15:04"
	if t, err := time.ParseInLocation(legacyFmt, s, time.UTC); err == nil {
		*e = EpochTime(t.Unix())
		return nil
	}

	return fmt.Errorf("EpochTime: cannot parse %q as epoch int, %q, or legacy %q layout",
		s, epochTimeFormat, legacyFmt)
}

// Int64 returns the raw Unix timestamp for internal logic that still needs the number.
func (e EpochTime) Int64() int64 {
	return int64(e)
}
