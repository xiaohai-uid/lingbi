package model

type Setting struct {
	Key   string `json:"key"`
	Value string `json:"value"`
}

type SettingsMap struct {
	Settings map[string]string `json:"settings"`
}