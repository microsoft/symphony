# shell helpers to read and validate input

function _prompt_input {
    input_description=${1}
    input_name=${2}

    echo $input_description
    read $input_name
}