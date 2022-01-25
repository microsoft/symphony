package helper

import (
	"bytes"
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"path/filepath"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestLoadEnvFile(t *testing.T) {
	// Set the environment variables.
	ExpectedKey := "FOO"
	ExpectedValue := "BAR"
	os.Setenv(TestEnvFilePath, filepath.Join("testdata", "foo.env"))
	assert.NotEqual(t, ExpectedValue, os.Getenv(ExpectedKey))
	err := LoadEnvFile(t)
	assert.NoError(t, err)
	assert.Equal(t, ExpectedValue, os.Getenv(ExpectedKey))
}

func TestLoadInvalidEnvFile(t *testing.T) {
	// Set the environment variables, point at invalid .env file
	filePath := filepath.Join("testdata", "invalid.env")
	os.Setenv(TestEnvFilePath, filePath)
	err := LoadEnvFile(t)
	assert.True(t, err != nil, "TestLoadEnvFile should return an error wehn invoked with invalid file path")
	assert.Equal(t, err.Error(), fmt.Sprintf("Can not read .env file: %s", filePath), "TestLoadEnvFile should return the correct error when invoked with invalid file path")
}

type SampleConfig struct {
	ResourceGroupName string `env:"TF_VAR_unit_test_resource_group_name"`
	DatabaseName      string `env:"TF_VAR_unit_test_database_name"`
	Password          string `env:"TF_VAR_unit_test_password" generated:"true"`
	SomeProperty      string `env:"TF_VAR_unit_test_some_object" property:"someProperty"`
	TestSchema        string `val:"true"`
	ConnectionString  string `kv:"connectionString"`
	Comment           string // Ignored
}

func TestDeserizeVariablesStruct(t *testing.T) {
	ExpectedResourceGroupName := "myResourceGroup"
	ExpectedDatabaseName := "myDatabaseName"
	ExpectedPassword := "veryStrongPassword!" // [SuppressMessage("Microsoft.Security", "CS001:SecretInline", Justification="Sample String for unit testing.")]
	SomeObject := `{ someProperty="propertyValue"}`
	ExpectedPropertyValue := "propertyValue"
	// Setup the environment variables
	os.Setenv("TF_VAR_unit_test_resource_group_name", ExpectedResourceGroupName)
	os.Setenv("TF_VAR_unit_test_database_name", ExpectedDatabaseName)
	os.Setenv("TF_VAR_unit_test_password", ExpectedPassword)
	os.Setenv("TF_VAR_unit_test_some_object", SomeObject)

	result := DeserializeVariablesStruct(&SampleConfig{})
	config := result.(*SampleConfig)
	assert.Equal(t, ExpectedResourceGroupName, config.ResourceGroupName)
	assert.Equal(t, ExpectedDatabaseName, config.DatabaseName)
	assert.Equal(t, ExpectedPassword, config.Password)
	assert.Equal(t, ExpectedPropertyValue, config.SomeProperty)
	// Clean up the environemnt variables
	os.Unsetenv("TF_VAR_unit_test_resource_group_name")
	os.Unsetenv("TF_VAR_unit_test_database_name")
	os.Unsetenv("TF_VAR_unit_test_password")
	os.Unsetenv("TF_VAR_unit_test_some_object")
}

func TestValidateVariablesWithGeneratedTag(t *testing.T) {
	config := &SampleConfig{}
	var buf bytes.Buffer
	log.SetOutput(&buf)
	defer func() {
		log.SetOutput(os.Stderr)
	}()
	assert.False(t, ValidateVariablesStruct(config, false))
	output := buf.String()
	assert.Contains(t, output, "Warning: Struct Field ResourceGroupName (env:TF_VAR_unit_test_resource_group_name) doesn't have any value.")
	assert.Contains(t, output, "Warning: Struct Field DatabaseName (env:TF_VAR_unit_test_database_name) doesn't have any value.")
	assert.Contains(t, output, "Warning: Struct Field Password (env:TF_VAR_unit_test_password) doesn't have any value.")
	assert.Contains(t, output, "Warning: Struct Field ConnectionString (kv:connectionString) doesn't have any value.")
	assert.Contains(t, output, "Warning: Struct Field TestSchema doesn't have any value.")
	//	t.Log(output) // You can use this line for debugging
	buf.Reset()

	config.ResourceGroupName = "myResourceGroup"
	config.DatabaseName = "myDatabaseName"
	config.SomeProperty = `{ someProperty="propertyValue"}`

	assert.True(t, ValidateVariablesStruct(config, true))
	output = buf.String()
	assert.Contains(t, output, "Warning: Struct Field Password (env:TF_VAR_unit_test_password) doesn't have any value. (Generated = true. skipped.)")
	buf.Reset()

	config.Password = "veryStrongPassword!" // [SuppressMessage("Microsoft.Security", "CS001:SecretInline", Justification="Sample String for unit testing.")]
	config.TestSchema = "someschema"
	config.ConnectionString = "ConnectionString" // [SuppressMessage("Microsoft.Security", "CS001:SecretInline", Justification="Sample String for unit testing.")]
	output = buf.String()
	assert.True(t, ValidateVariablesStruct(config, false))
	output = buf.String()
	assert.NotContains(t, output, "Warning: Struct Field Password (env:TF_VAR_unit_test_password) doesn't have any value.")

}

func TestValidateVariablesStruct(t *testing.T) {
	config := &SampleConfig{}
	var buf bytes.Buffer
	log.SetOutput(&buf)
	defer func() {
		log.SetOutput(os.Stderr)
	}()
	assert.False(t, ValidateVariablesStruct(config, true))
	output := buf.String()
	assert.Contains(t, output, "Warning: Struct Field ResourceGroupName (env:TF_VAR_unit_test_resource_group_name) doesn't have any value.")
	assert.Contains(t, output, "Warning: Struct Field DatabaseName (env:TF_VAR_unit_test_database_name) doesn't have any value.")
	// t.Log(output) // You can use this line for debugging
	buf.Reset()

	config.ResourceGroupName = "value1"
	assert.False(t, ValidateVariablesStruct(config, true))
	output = buf.String()
	assert.NotContains(t, output, "Warning: Struct Field ResourceGroupName (env:TF_VAR_unit_test_resource_group_name) doesn't have any value.")
	assert.Contains(t, output, "Warning: Struct Field DatabaseName (env:TF_VAR_unit_test_database_name) doesn't have any value.")

	buf.Reset()
	config.DatabaseName = "value2"
	assert.False(t, ValidateVariablesStruct(config, true))
	output = buf.String()
	assert.NotContains(t, output, "Warning: Struct Field ResourceGroupName (env:TF_VAR_unit_test_resource_group_name) doesn't have any value.")
	assert.NotContains(t, output, "Warning: Struct Field DatabaseName (env:TF_VAR_unit_test_database_name) doesn't have any value.")
	assert.Contains(t, output, "Warning: Struct Field SomeProperty (env:TF_VAR_unit_test_some_object) doesn't have any value.")
	//t.Log(output)
}

type Logging struct {
	Message string
}

func TestGenerateYamlFromTemplate(t *testing.T) {
	log := &Logging{
		Message: "hello",
	}
	templateFile := filepath.Join("testdata", "some.yml.tmpl")
	targetFile := "some.yml"
	err := GenerateYamlFileFromTemplateE(templateFile, targetFile, log)
	defer func() {
		os.Remove(targetFile)
	}()
	require.NoError(t, err)
	content, err := ioutil.ReadFile("some.yml")
	require.NoError(t, err)
	assert.Equal(t, "hello", string(content))
}

type yamlConfig struct {
	Name    string
	Trigger []int
	Pool    struct {
		VMImage string
	}
}

func TestGetYamlVariables(t *testing.T) {

	// set file path
	filePath := "testdata/foo.yaml"

	// get values from yaml file
	values, err := GetYamlVariables(filePath, &yamlConfig{})
	require.NoError(t, err)

	// cast result
	config := values.(*yamlConfig)
	t.Log(fmt.Sprintf("\n--- yaml values:\n%v\n", *config))

	assert.Equal(t, config.Name, "someName")
	assert.Equal(t, config.Trigger, []int{1, 2})
	assert.Equal(t, config.Pool.VMImage, "ubuntu-latest")
}

func TestGetYamlVariablesWithInvalidPath(t *testing.T) {

	// set file path
	filePath := "testdata/invalid.yaml"

	// get values from yaml file
	_, err := GetYamlVariables(filePath, &yamlConfig{})
	require.Error(t, err)
	assert.Equal(t, err.Error(), "Path to Yaml file not set or invalid: testdata/invalid.yaml")
}
