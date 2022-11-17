# shell helpers to read and validate input

function _prompt_input {
    input_description=${1}
    input_name=${2}

    echo $input_description
    read $input_name
}

function _validate_inputs {
    if [ -z "$ORCHESTRATOR" ]; then
      _error "Please specify an orchestrator "
      usage
    elif [ "$ORCHESTRATOR" == "-h" ] || [ "$ORCHESTRATOR" == "--help" ]; then
      usage
    fi

    if [ -z "$IACTOOL" ]; then
      _error "Please specify an iac tool "
      usage
    fi
}


function usage() {

    _helpText=" Usage: $me <provider> <iac_tool>
 arguments:
    provider   (required)    azdo|github       specify the desired orchestrator
    iac_tool   (required)    terraform|bicep   specify the desired iac tool to configure

environment variables can be configured to store 
"      
    _information "$_helpText" 1>&2
    exit 0  
}