package helper

import (
	"bufio"
	"crypto/tls"
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"reflect"
	"regexp"
	"strings"
	"testing"
	"text/template"
	"time"

	http_helper "github.com/gruntwork-io/terratest/modules/http-helper"
	"github.com/joho/godotenv"
	"github.com/mitchellh/mapstructure"
	"gopkg.in/yaml.v2"
)

const (
	// TestEnvFilePath is the environment variable key for getting .env file path
	TestEnvFilePath = "TEST_ENV_FILE_PATH"
)

// LoadEnvFile read an .env file that has a path by the value of TEST_ENV_FILE_PATH environment variable.
func LoadEnvFile(t *testing.T) error {
	envFileName := os.Getenv(TestEnvFilePath)
	err := godotenv.Load(envFileName)
	if err != nil {
		return fmt.Errorf("Can not read .env file: %s", envFileName)
	}
	return nil
}

// DeserializeVariablesStruct fill the value from environment variables.
func DeserializeVariablesStruct(s interface{}) interface{} {
	fields := reflect.ValueOf(s).Elem()
	for i := 0; i < fields.NumField(); i++ {
		typeField := fields.Type().Field(i)
		environmentVariablesKey := typeField.Tag.Get("env")
		if fields.Field(i).Kind() == reflect.String {
			// check if we want a property inside a complex object
			propertyKey, exists := typeField.Tag.Lookup("property")
			if exists {
				// get object string
				objectString := os.Getenv(environmentVariablesKey)
				// grab property value inside string
				propertyValue := getPropertyValueFromString(objectString, propertyKey)
				// set the value in the correct field
				fields.Field(i).SetString(propertyValue)
			} else {
				fields.Field(i).SetString(os.Getenv(environmentVariablesKey))
			}
		}

	}
	return s
}

func getPropertyValueFromString(object string, propertyKey string) string {
	// compile regex to look for key="value"
	regexString := fmt.Sprintf(`%s=\"(.*?)\"`, propertyKey)
	re := regexp.MustCompile(regexString)
	match := string(re.Find([]byte(object)))
	if len(match) == 0 {
		log.Printf("Warning: Could not find property with key %s\n", propertyKey)
		return ""
	}
	match = strings.Replace(match, "\"", "", -1)
	propertyValue := strings.Split(match, "=")[1]
	return propertyValue
}

// ValidateVariablesStruct validate if the all parameters has the value. isSkipGenerated allows ignore a field that has the `generated:"true"` tag.
func ValidateVariablesStruct(s interface{}, isSkipGenerated bool) bool {
	fields := reflect.ValueOf(s).Elem()
	flag := true
	for i := 0; i < fields.NumField(); i++ {
		value := fields.Field(i)
		typeField := fields.Type().Field(i)
		if value.Kind() == reflect.String {
			if len(value.String()) == 0 {
				if !IsAnyTagExists(typeField.Tag) {
					continue
				} else if isSkipGenerated && IsTagExists(typeField.Tag, "env") && IsTagExists(typeField.Tag, "generated") {
					log.Printf("Warning: Struct Field %s (env:%s) doesn't have any value. (Generated = true. skipped.)\n", typeField.Name, typeField.Tag.Get("env"))
					continue
				} else if isSkipGenerated && IsTagExists(typeField.Tag, "kv") {
					log.Printf("Warning: Struct Field %s (kv:%s) doesn't have any value. (Generated = true. skipped.)\n", typeField.Name, typeField.Tag.Get("kv"))
					continue
				} else if isSkipGenerated && IsTagExists(typeField.Tag, "val") {
					log.Printf("Warning: Struct Field %s doesn't have any value. (Generated = true. skipped.)\n", typeField.Name)
					continue
				} else if IsTagExists(typeField.Tag, "kv") {
					log.Printf("Warning: Struct Field %s (kv:%s) doesn't have any value.\n", typeField.Name, typeField.Tag.Get("kv"))
					continue
				} else if IsTagExists(typeField.Tag, "val") {
					log.Printf("Warning: Struct Field %s doesn't have any value.\n", typeField.Name)
					flag = false
				} else {
					log.Printf("Warning: Struct Field %s (env:%s) doesn't have any value.\n", typeField.Name, typeField.Tag.Get("env"))
					flag = false
				}
			}
		} else {
			return false
		}
	}
	return flag
}

// IsTagExists test if the tag is there or not.
func IsTagExists(tag reflect.StructTag, tagName string) bool {
	_, ok := tag.Lookup(tagName)
	return ok
}

// IsAnyTagExists test if any tags are exists.
func IsAnyTagExists(tag reflect.StructTag) bool {
	_, isEnv := tag.Lookup("env")
	_, isKv := tag.Lookup("kv")
	_, isVal := tag.Lookup("val")
	return isEnv || isKv || isVal
}

// GenerateYamlFileFromTemplateE will create Yaml from template and config object
func GenerateYamlFileFromTemplateE(templateFileName, targetFileName string, config interface{}) error {

	content, err := ioutil.ReadFile(templateFileName)
	if err != nil {
		return err
	}
	tmpl, err := template.New(targetFileName).Parse(string(content))
	if err != nil {
		return err
	}
	f, err := os.Create(targetFileName)
	w := bufio.NewWriter(f)

	defer func() {
		f.Close()
		//	os.Remove(jobYamlFilePath) // You can comment out when you want to debug.
	}()

	err = tmpl.Execute(w, config)
	if err != nil {
		return err
	}
	w.Flush()
	return nil
}

// GetYamlVariables reads the yaml file in filePath and returns valus specified by interface s
func GetYamlVariables(filePath string, s interface{}) (interface{}, error) {
	// read yaml file
	yamlFile, err := ioutil.ReadFile(filePath)
	if err != nil {
		return nil, fmt.Errorf("Path to Yaml file not set or invalid: %s", filePath)
	}

	// parse yaml file
	m := make(map[interface{}]interface{})
	err = yaml.UnmarshalStrict(yamlFile, &m)
	if err != nil {
		return nil, fmt.Errorf("Error parsing Yaml File %s: %s", filePath, err.Error())
	}

	err = mapstructure.Decode(m, &s)
	return s, nil
}

// SetupTestCase initializes a test and loads the environment file specified in TEST_ENV_FILE_PATH
// It will cause the test to fail if the environment file is not available
func SetupTestCase(t *testing.T) func(t *testing.T) {
	// setup code in here.
	err := LoadEnvFile(t)
	if err != nil {
		t.Fatal(err)
	}
	return func(t *testing.T) {
		// teardown code in here
	}
}

// TestEndpointIsResponding test an endpoint for availability. Returns true if endpoint is available, false otherwise
func TestEndpointIsResponding(t *testing.T, endpoint string) bool {
	tlsConfig := tls.Config{}
	err := http_helper.HttpGetWithRetryWithCustomValidationE(
		t,
		fmt.Sprintf("http://%s", endpoint),
		&tlsConfig,
		1,
		10*time.Second,
		func(statusCode int, body string) bool {
			if statusCode == 200 {
				return true
			}
			if statusCode == 404 {
				t.Log("Warning: 404 response from endpoint. Test will still PASS.")
				return true
			}
			return false
		},
	)
	return err == nil
}
