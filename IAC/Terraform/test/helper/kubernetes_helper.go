package helper

import (
	"encoding/json"
	"testing"

	"github.com/gruntwork-io/terratest/modules/k8s"
	batch "k8s.io/api/batch/v1"
)

// GetJobE get the job and status.
func GetJobE(t *testing.T, options *k8s.KubectlOptions, name string) (*batch.Job, error) {
	output, err := k8s.RunKubectlAndGetOutputE(t, options, "get", "job", name, "-o", "json")
	if err != nil {
		return nil, err
	}
	var job batch.Job
	err = json.Unmarshal([]byte(output), &job)
	if err != nil {
		return nil, err
	}
	return &job, nil
}
