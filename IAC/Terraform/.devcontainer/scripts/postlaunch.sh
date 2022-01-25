#!/usr/bin/env bash


copy_override_tf() {
    local DEPLOYMENTS
    pushd ~/repos/$AZDO_PROJECT_NAME/Terraform-Code/terraform
        DEPLOYMENTS=(`find . -type d | grep '.\/[0-9][0-9]' | cut -c 3- | grep -v '^01_init' | grep -v '.*\/modules\/.*' | grep -v '.*\/modules' | grep '.*\/.*' | sort`)
        for deployment in "${DEPLOYMENTS[@]}"
        do
            pushd $deployment
                cp /home/vscode/.lucidity/_override.tf .
                cp /home/vscode/.lucidity/.envcrc-tf ./.envrc
                direnv allow
            popd
        done    
    popd
}

copy_env_rc(){ 
    pushd /home/vscode/repos/Terraform-Code
        cp /home/vscode/.lucidity/.envrc .
        direnv allow
    popd
}

add_dir_env_to_bash_rc() {
    echo 'eval "$(direnv hook bash)"' >> ~/.bashrc
}

main() {
    copy_override_tf    
    add_dir_env_to_bash_rc
    copy_env_rc
}

main