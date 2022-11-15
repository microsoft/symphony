#!/bin/bash
source ./../utilities/shell_logger.sh

function remove_tf_content(){
    _information "Remove Terraform IaC modules"
    rm -r ./../../IAC/Terraform/*
    rm  -r ./../../IAC/Terraform

    _information "Remove Terraform env"
    rm -r ./../../env/terraform/*
    rm -r ./../../env/terraform

    _information "Remove Terraform Azdo pipeline"
    rm ./../../.azure-pipelines/*.terraform*.yml

    _information "Remove Terraform Github workflows"
    rm ./../../.github/workflows/*.terraform*.yml

    _information "Remove Terraform orchestrators scripts"
    rm ./../orchestrators/*.tf.*.sh
    rm ./../orchestrators/*terraform*.sh
    rm ./../orchestrators/*tflint.sh
} 

function remove_bicep_content(){

    _information "Remove Bicep IaC modules"
    rm -r ./../../IAC/Bicep/*
    rm -r ./../../IAC/Bicep

    _information "Remove Bicep Azdo pipeline"
    rm ./../../.azure-pipelines/*.bicep*.yml

    _information "Remove Bicep Github workflows"
    rm ./../../.github/workflows/*.bicep*.yml

    _information "Remove Bicep orchestrators scripts"
    rm ./../orchestrators/*bicep*.sh
    rm ./../orchestrators/*powershell*.sh
    rm ./../orchestrators/*shellspec*.sh
    rm ./../orchestrators/*pester.sh
    rm ./../orchestrators/setup-armttk.sh
}