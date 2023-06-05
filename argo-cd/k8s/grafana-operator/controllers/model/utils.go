package model

import (
	"crypto/rand"
	"encoding/base64"
)

func generateRandomBytes(n int) []byte {
	b := make([]byte, n)
	_, err := rand.Read(b)
	if err != nil {
		panic(err)
	}
	return b
}

func RandStringRunes(s int) string {
	b := generateRandomBytes(s)
	return base64.URLEncoding.EncodeToString(b)
}

func MergeAnnotations(requested map[string]string, existing map[string]string) map[string]string {
	if existing == nil {
		return requested
	}

	for k, v := range requested {
		existing[k] = v
	}
	return existing
}

func getDefaultInt32(val1 *int32, val2 int32) int32 {
	if val1 != nil {
		return *val1
	}
	return val2
}
