#!/bin/bash
# This script upgrades the providers of the supplied Terraform project and prints the resulting terraform lock file content to the stdout
# It assumes that you have the 2 following files in your Terraform project:
#  - "versions.tf" that defines a "terraform" block with the list of providers defined in the "required_providers" sub-block
#  - ".terraform.lock.hcl" generated by the "terraform init <...>" commands, that defines the tree of plugins to be installed into ".terraform/"
# Expected arguments:
#  1. the path to the terraform project (must be an existing directory on the local filesystem)

## Write message to stderr to avoid polluting stdout
log_message() {
  >&2 echo "$1"
}
## Log an error message and exit
error_message() {
  log_message "ERROR: $1"
  exit 1
}

test -n "$1" || error_message "please provide the path to the directory of a terraform project."
terraform_project_dir="$1"

set -eux -o pipefail

test -d "${terraform_project_dir}" || error_message "the directory ${terraform_project_dir} does not exist."

temp_dir="$(mktemp -d)"

command -v terraform >/dev/null 2>&1 

log_message "Upgrading using terraform $(terraform version)"

declare -a terraform_required_files=("versions.tf" ".terraform.lock.hcl")

## Create a temporary terraform project with only the required files within (do not risk manipulating other resources of the project)
for required_file in "${terraform_required_files[@]}"
do
  test -f "${terraform_project_dir}/${required_file}" || error_message "ERROR: the file ${terraform_project_dir}/${required_file} does not exist."
  cp "${terraform_project_dir}/${required_file}" "${temp_dir}/"
done

## Upgrade the versions in the temporary directory
cd "${temp_dir}"
>&2 terraform init -input=false -backend=false -upgrade

## Prints the content of the new terraform lock file to stdout
cat "${temp_dir}/.terraform.lock.hcl"
echo # Always add an empty line at the end of the file (POSIX)

## Cleanup
>&2 rm -rf "${temp_dir}" || true

exit 0