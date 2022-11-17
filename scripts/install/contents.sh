#!/bin/bash

INSTALL_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
source $SCRIPT_DIR/../utilities/shell_logger.sh

function remove_tf_content(){
    _information "Remove Terraform IaC modules"
    rm -r $INSTALL_DIR/../../IAC/Terraform/*
    rm  -r $INSTALL_DIR/../../IAC/Terraform

    _information "Remove Terraform env"
    rm -r $INSTALL_DIR/../../env/terraform/*
    rm -r $INSTALL_DIR/../../env/terraform

    _information "Remove Terraform Azdo pipeline"
    rm $INSTALL_DIR/../../.azure-pipelines/*.terraform*.yml

    _information "Remove Terraform Github workflows"
    rm $INSTALL_DIR/../../.github/workflows/*.terraform*.yml

    _information "Remove Terraform orchestrators scripts"
    rm $INSTALL_DIR/../orchestrators/*.tf.*.sh
    rm $INSTALL_DIR/../orchestrators/*terraform*.sh
    rm $INSTALL_DIR/../orchestrators/*tflint.sh
} 

function remove_bicep_content(){

    _information "Remove Bicep IaC modules"
    rm -r $INSTALL_DIR/../../IAC/Bicep/*
    rm -r $INSTALL_DIR/../../IAC/Bicep

    _information "Remove Bicep Azdo pipeline"
    rm $INSTALL_DIR/../../.azure-pipelines/*.bicep*.yml

    _information "Remove Bicep Github workflows"
    rm $INSTALL_DIR/../../.github/workflows/*.bicep*.yml

    _information "Remove Bicep orchestrators scripts"
    rm $INSTALL_DIR/../orchestrators/*bicep*.sh
    rm $INSTALL_DIR/../orchestrators/*powershell*.sh
    rm $INSTALL_DIR/../orchestrators/*shellspec*.sh
    rm $INSTALL_DIR/../orchestrators/*pester.sh
    rm $INSTALL_DIR/../orchestrators/setup-armttk.sh
}