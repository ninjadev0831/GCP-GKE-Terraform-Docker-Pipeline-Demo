#!/bin/bash
set -euo pipefail

# project="$1"
# region="$2"
# zone="$3"

# TERRAFORM_VER=0.12.18
# TERRAGRUNT_VER=0.21.10
# KUSTOMIZE_VER=3.5.3

# MICROSERVICES=(
#   adservice
#   cartservice
#   checkoutservice
#   currencyservice
#   emailservice
#   frontend
#   paymentservice
#   productcatalogservice
#   recommendationservice
#   shippingservice
# )

info() {
  echo "[[ INFO ]] $1"
}

abort() {
  echo "[[ ERROR ]] $1"
  exit 1
}

set +u
if [[ -z "$TF_VAR_project_id" ]]; then
  abort '$TF_VAR_project_id environment variable must be set. Aborting.'
fi
set -u

if (gcloud -q auth print-access-token 2>&1 1>/dev/null); then
  info "You are already authenticated in gcloud, skipping authenication"
else
  info "Authenticating in GCP with gcloud"
  gcloud -q auth login
fi

info "Setting up \$GOOGLE_CLOUD_KEYFILE_JSON environment variable"
export GOOGLE_CLOUD_KEYFILE_JSON="$HOME/.config/gcloud/application_default_credentials.json"
if ! (grep "GOOGLE_CLOUD_KEYFILE_JSON" "$HOME/.profile" 2>&1 1>/dev/null); then
  echo "export GOOGLE_CLOUD_KEYFILE_JSON=\"$GOOGLE_CLOUD_KEYFILE_JSON\"" >> "$HOME/.profile"
fi

if [[ ! -f "$GOOGLE_CLOUD_KEYFILE_JSON" ]]; then
  info "Setting up application-default service account for GCP"
  gcloud auth application-default login --no-launch-browser
fi

if (gcloud projects describe -q --verbosity=none "$TF_VAR_project_id" 2>&1 1>/dev/null); then
  info "Project already exists, skipping creation"
else
  info "Creating GCP project"
  gcloud projects create -q "$TF_VAR_project_id"
fi
gcloud config set -q project "$TF_VAR_project_id"

info "Attaching billing account to the project"
billing_id="$(gcloud beta billing accounts list | awk 'NR == 2 {print $1}')"
gcloud beta billing projects link -q "$TF_VAR_project_id" --billing-account "$billing_id"

if (gsutil ls -b "gs://${TF_VAR_project_id}_terraform-state/" 2>&1 1>/dev/null); then
  info "Cloud Storage bucket for Terraform state already exists, skipping creation"
else
  info "Creating Cloud Storage bucket for Terraform state"
  gsutil mb -l eu "gs://${TF_VAR_project_id}_terraform-state"
  gsutil versioning set on "gs://${TF_VAR_project_id}_terraform-state"
fi

# if [[ ! -f "./bin/terraform" ]]; then
#   info "Downloading Terraform"
#   cd ./bin
#   wget -O terraform.zip "https://releases.hashicorp.com/terraform/$TERRAFORM_VER/terraform_${TERRAFORM_VER}_linux_amd64.zip"
#   unzip terraform.zip
#   chmod +x terraform
#   rm terraform.zip
#   cd -
# fi

# if [[ ! -f "./bin/terragrunt" ]]; then
#   info "Downloading Terragrunt"
#   cd ./bin/
#   wget -O terragrunt "https://github.com/gruntwork-io/terragrunt/releases/download/v$TERRAGRUNT_VER/terragrunt_linux_amd64"
#   chmod +x terragrunt
#   cd -
# fi

# if [[ ! -f "./bin/kustomize" ]]; then
#   info "Downloading Kustomize"
#   cd ./bin/
#   curl -sSL --output - "https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv$KUSTOMIZE_VER/kustomize_v${KUSTOMIZE_VER}_linux_amd64.tar.gz" | tar xz
#   chmod +x kustomize
#   cd -
# fi

# info "Kustomizing image tags in k8s manifests"
# cd ./kubernetes/
# for microservice in "${MICROSERVICES[@]}"; do
#   ../bin/kustomize edit set image "$microservice=gcr.io/$TF_VAR_project_id/$microservice"
# done
# cd -

# gcloud config set -q compute/region $region
# gcloud config set -q compute/zone $zone
