# shell helpers to read and validate input

function _prompt_input {
    input_description=${1}
    input_name=${2}

    echo ""
    echo -n "> $input_description : "
    read $input_name
}

function _validate_inputs {
  code=0
  if [ -z "$ORCHESTRATOR" ]; then
    _error "Please specify an orchestrator "
    code=1
  fi

  if [ -z "$IACTOOL" ]; then
    _error "Please specify an iac tool "
    code=2
  fi

  echo ""
  return $code
}


function usage() {
    _helpText=" Usage: $me <command> <sub command> <parameters>
  commands:
    provision  Set up the required infrastructure needed for symphony
    pipeline   
      sub commands:
        config 
          arguments:
            provider   (required)    azdo|github       specify the desired orchestrator
            iac_tool   (required)    terraform|bicep   specify the desired iac tool to configure
        example:
          symphony pipeline config azdo terraform
          symphony pipeline config github bicep
 
"      
    _information "$_helpText" 1>&2
    exit 0  
}