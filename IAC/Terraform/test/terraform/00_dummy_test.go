// +build 00 dummy

package terraform_test

import (
	"os"
	"testing"

	"github.com/stretchr/testify/assert"
)

func Test00DummyTesting(t *testing.T) {
	DoSomething(t)
	assert.True(t, true)
}

// Uncomment to demonstrate a failing test.
// func Test00DummyFailTesting(t *testing.T) {
// 	assert.True(t, false)
// }

func DoSomething(t *testing.T) {
	t.Log("Doing Something...")
	value := os.Getenv("FOO")
	t.Log(value)
}
