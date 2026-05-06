package telemetry

import (
	"fmt"
	"cmp"
	"math"
	"slices"
	"time"


	
    "github.com/Fleexa-Graduation-Project/Backend/models"

)

type ChartPoint struct {
	Label string  `json:"label"` // x-axis
	Value float64 `json:"value"` // y-axis
}

// temp min max avg state
type TempState struct {
	Min     float64 `json:"min"`
	Max     float64 `json:"max"`
	Average float64 `json:"average"`
}


 func PeriodCutoff(now int64, period string) int64 {
   switch period {
	case "24h":
		return now - 86400 // 24 * 60 * 60
	case "7d":
		return now - 604800 // 7 * 24 * 60 * 60
	case "1m":
		return now - 2592000 // 30 * 24 * 60 * 60
	default:
		return 0
	}
}
func GetTimeFormat(period string) string {
	switch period {
	case "24h":
		return "15:04"
	case "7d":
		return "Mon"
	case "1m":
		return "Jan 02"
	default:
		return "2006-01-02"
	}
}

func FilterTime(history []models.Telemetry, metric string, period string, now int64) ([]ChartPoint, float64) {    
	cutoff := PeriodCutoff(now, period)
	timeFormat := GetTimeFormat(period)
	maxVal := -math.MaxFloat64

    var mapCapacity int
    switch period {
    case "24h":
        mapCapacity = 24
    case "7d":
        mapCapacity = 7
    case "1m":
        mapCapacity = 30
    default:
        mapCapacity = 30
    }

    groupedData := make(map[string]float64, mapCapacity)
    countMap := make(map[string]int, mapCapacity)

    for _, record := range history {
        if cutoff > 0 && record.Timestamp < cutoff {
            break 
        }

        if val, exists := record.Payload[metric]; 
		exists {
            recordTime := time.Unix(record.Timestamp, 0)
            var timeLabel string
			if period == "24h" {
				roundedHour := (recordTime.Hour() / 2) * 2
				timeLabel = fmt.Sprintf("%02d:00", roundedHour)
			} else {
				timeLabel = recordTime.Format(timeFormat)
			}


            if strVal, ok := val.(string); 
			ok && strVal == "ON" {
                groupedData[timeLabel] += 0.083
            }

            if floatVal, ok := val.(float64); 
			ok {
                groupedData[timeLabel] += floatVal
                countMap[timeLabel]++
            
				} else if intVal, ok := val.(int); 
				ok {
                groupedData[timeLabel] += float64(intVal)
                countMap[timeLabel]++
            }
        }
    }

    chartResult := make([]ChartPoint, 0, len(groupedData))
    for label, total := range groupedData {
        finalValue := total
        if count, wasSensor := countMap[label]; wasSensor && count > 0 {
            finalValue = total / float64(count)
        }

		if finalValue > maxVal {
			maxVal = finalValue
		}
        chartResult = append(chartResult, ChartPoint{
            Label: label,
            Value: math.Round(finalValue*10) / 10,
        })
    }

    slices.SortFunc(chartResult, func(a, b ChartPoint) int {
        return cmp.Compare(a.Label, b.Label)
    })

	if maxVal == -math.MaxFloat64 {
		maxVal = 0.0
	}

    return chartResult, math.Round(maxVal*10)/10
}
// get the max y value for charts
func GetChartMax(data []ChartPoint) float64 {
	if len(data) == 0 {
		return 0.0
	}
	maxVal := -math.MaxFloat64
	for _, pt := range data {
		if pt.Value > maxVal {
			maxVal = pt.Value
		}
	}
	return maxVal
}

func TimeAgo(ts int64, now int64) string {
	diff := now - ts
	if diff < 60 {
		return "Just now"
	}
	mins := diff / 60
	if mins < 60 {
		if mins == 1 {
			return "1 min ago"
		}
		return fmt.Sprintf("%d mins ago", mins)
	}
	hours := mins / 60
	if hours < 24 {
		if hours == 1 {
			return "1 hour ago"
		}
		return fmt.Sprintf("%d hours ago", hours)
	}
	days := hours / 24
	if days == 1 {
		return "1 day ago"
	}
	return fmt.Sprintf("%d days ago", days)
}

func CalculateTempState(history []models.Telemetry, metric string, now int64) (TempState, error) {
    if len(history) == 0 {
        return TempState{}, fmt.Errorf("no data")
    }

	
    overallMin := math.MaxFloat64
    overallMax := -math.MaxFloat64
    overallSum := 0.0
    overallCount := 0
    cutoffTime := now - 86400

    for _, record := range history {
        if record.Timestamp < cutoffTime {
            break 
        }

        if val, exists := record.Payload[metric]; exists {
            var num float64
            if floatVal, ok := val.(float64); 
			ok {
                num = floatVal
            } else if intVal, ok := val.(int); 
			ok {
                num = float64(intVal)
            } else {
                continue
            }

            if num < overallMin {
                overallMin = num
            }
            if num > overallMax {
                overallMax = num
            }
            overallSum += num
            overallCount++
        }
    }

    if overallCount == 0 {
        return TempState{Min: 0, Max: 0, Average: 0}, nil
    }

    return TempState{
        Min:     math.Round(overallMin*10) / 10,
        Max:     math.Round(overallMax*10) / 10,
        Average: math.Round((overallSum/float64(overallCount))*10) / 10,
    }, nil
}



//calculating the avg unlock time of the door based on the last 24h
func CalculateAvgUnlock(history []models.Telemetry, now int64) float64 {
	if len(history) == 0 {
		return 0
	}

	var totalUnlockTime float64
	var unlockCycle int
	var unlockTime int64

	
	for i := len(history) - 1; i >= 0; i-- {
		record := history[i]
		state, ok := record.Payload["lock_state"].(string)
		if !ok {
			continue
		}

		if state == "UNLOCKED" && unlockTime == 0 {
			unlockTime = record.Timestamp   //door opened, start timer
		} else if state == "LOCKED" && unlockTime > 0 {
			duration := record.Timestamp - unlockTime //door closed, calculate duration
			if duration > 0 {
				totalUnlockTime += float64(duration)
				unlockCycle++
			}
			unlockTime = 0         //reset for the next cycle
		}
	}

	if unlockTime > 0 {  // if door is still open
		duration := now - unlockTime
		if duration > 0 {   // calculate duration up to now
			totalUnlockTime += float64(duration)
			unlockCycle++
		}
	}

	if unlockCycle == 0 {
		return 0 
	}

	// convert time from sec to min and calculate avg
	avgMinutes := (totalUnlockTime / 60.0) / float64(unlockCycle)
	return math.Round(avgMinutes*10) / 10
}

func FormatDoorEvents(history []models.Telemetry) []map[string]interface{} {
	formatted := make([]map[string]interface{}, 0, len(history))
	
	for _, record := range history {
		state, ok := record.Payload["lock_state"].(string)
		if !ok {
			continue
		}
		
		// Format the event label
		var label string
		if state == "UNLOCKED" {
			label = "Door unlocked"
		} else {
			label = "Door locked"
		}

		// Format the time string (e.g., "8:49 PM")
		t := time.Unix(record.Timestamp, 0)
		timeStr := t.Format("3:04 PM")

		formatted = append(formatted, map[string]interface{}{
			"event":     label,
			"time":      timeStr,
			"timestamp": record.Timestamp, 
		})
	}
	return formatted
}

func FormatACEvents(history []models.Telemetry) []map[string]interface{} {
	formatted := make([]map[string]interface{}, 0, len(history))
	
	for _, record := range history {
		state, ok := record.Payload["power_state"].(string)
		if !ok {
			continue
		}
		
		label := "A/C turned " + state

		t := time.Unix(record.Timestamp, 0)
		timeStr := t.Format("3:04 PM")

		formatted = append(formatted, map[string]interface{}{
			"event":     label,
			"time":      timeStr,
			"timestamp": record.Timestamp, 
		})
	}
	return formatted
}
//gas alerts and warnings
func GetGasEvents(history []models.Telemetry) []map[string]interface{} {
	formatted := make([]map[string]interface{}, 0)
	now := time.Now().Unix()

	for _, record := range history {
		if len(formatted) == 5 {
			break
		}
		status, _ := record.Payload["status"].(string)
		alarm, _ := record.Payload["alarm_on"].(bool)
		
		if status == "SAFE" && !alarm {
			continue                    //skip normal readings
		}

		description := "Gas level Exceed safe limit"
		if status == "WARNING" {
			description = "Gas spike detected"
		}

		levelStr := ""
		if val, ok := record.Payload["gas_level"].(float64); ok {
			levelStr = fmt.Sprintf("%.0f PPM", val)
		} else if intVal, ok := record.Payload["gas_level"].(int); ok {
			levelStr = fmt.Sprintf("%d PPM", intVal)
		}

		formatted = append(formatted, map[string]interface{}{
		"description": description,
			"gas_level":   levelStr,
			"time":        TimeAgo(record.Timestamp, now),
			"timestamp":   record.Timestamp,
		})
	}
	return formatted
}

//calculating the total used hours for the last 5 days
func CalculateACUsage(history []models.Telemetry, now int64, period string) []ChartPoint {
	if len(history) == 0 {
		return []ChartPoint{}
	}
	timeFormat := GetTimeFormat(period)
	dailyUsage := make(map[string]float64)
	var onTime int64
	
	for i := len(history) - 1; i >= 0; i-- {  //get used intervals
		record := history[i]
		state, ok := record.Payload["power_state"].(string)
		if !ok {
			continue
		}

		if state == "ON" && onTime == 0 {
			onTime = record.Timestamp
		} else if state == "OFF" && onTime > 0 {
			duration := record.Timestamp - onTime
			if duration > 0 {
				dayLabel := time.Unix(onTime, 0).Format(timeFormat) 
				dailyUsage[dayLabel] += float64(duration)
			}
			onTime = 0
		}
	}

	
	if onTime > 0 {              // if AC is still on
		duration := now - onTime
		if duration > 0 {
			dayLabel := time.Unix(onTime, 0).Format(timeFormat) 
			dailyUsage[dayLabel] += float64(duration)
		}
	}
	
	var chartResult []ChartPoint
	for label, totalSeconds := range dailyUsage {  //convert to hours
		hours := totalSeconds / 3600.0
		chartResult = append(chartResult, ChartPoint{
			Label: label,
			Value: math.Round(hours*10) / 10, 
		})
	}

	return chartResult
}


func FormatACTime(seconds int64) string {
	if seconds <= 0 {
		return "0m"
	}
	hours := seconds / 3600
	minutes := (seconds % 3600) / 60

	if hours > 0 {
		return fmt.Sprintf("%dh %dm", hours, minutes)
	}
	return fmt.Sprintf("%dm", minutes)
}

//calculating ac run time last 24h
func CalculateACRunTime(history []models.Telemetry, now int64) int64 {
	if len(history) == 0 {
		return 0
	}

	var totalSeconds int64 = 0
	var onTime int64 = 0

	for i := len(history) - 1; i >= 0; i-- {
		record := history[i]
		state, ok := record.Payload["power_state"].(string)
		if !ok {
			continue
		}

		if state == "ON" && onTime == 0 {
			onTime = record.Timestamp   
		} else if state == "OFF" && onTime > 0 {
			duration := record.Timestamp - onTime 
			if duration > 0 {
				totalSeconds += duration  
			}
			onTime = 0 
		}
	}
	
	if onTime > 0 {
		duration := now - onTime
		if duration > 0 {
			totalSeconds += duration
		}
	}

	return totalSeconds
}



//get alerts by time and severity for entire system (system overview part)
func GetAlerts(alertList []models.Alert, period string) map[string][]ChartPoint {
	timeFormat := GetTimeFormat(period)
	warningMap := make(map[string]float64)
	criticalMap := make(map[string]float64)

	for _, alert := range alertList {
		label := time.Unix(alert.Timestamp, 0).Format(timeFormat)
		if alert.Severity == "WARNING" || alert.Severity == "warning" {
			warningMap[label]++
		} else if alert.Severity == "CRITICAL" || alert.Severity == "critical"{
			criticalMap[label]++
		}
	}

	mapToSortedChart := func(m map[string]float64) []ChartPoint {
		var chart []ChartPoint
		for k, v := range m {
			chart = append(chart, ChartPoint{Label: k, Value: v})
		}
		slices.SortFunc(chart, func(a, b ChartPoint) int {
			return cmp.Compare(a.Label, b.Label)
		})
		return chart
	}

	return map[string][]ChartPoint{
		"warning":  mapToSortedChart(warningMap),
		"critical": mapToSortedChart(criticalMap),
	}
}


func CalculateEnergy(acUsage []ChartPoint) []ChartPoint {
	const dailyPower = 0.132
	const acPower = 1.5

	var energyChart []ChartPoint
	
	for _, point := range acUsage {
		dailyAC := point.Value * acPower
		
		totalConsumption := dailyAC+ dailyPower

		energyChart = append(energyChart, ChartPoint{
			Label: point.Label,
			Value: math.Round(totalConsumption*10) / 10,
		})
	}

	return energyChart
}