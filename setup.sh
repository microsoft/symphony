#!/bin/bash

LOCATION="westus"
APP_REPO="https://github.com/dotnet-architecture/eShopOnWeb.git"
APP_COMMIT="a87f571"
APP_WEB_NAME="eshopwebmvc"
APP_WEB_DOCKERFILE="src/Web/Dockerfile"
APP_API_NAME="eshoppublicapi"
APP_API_DOCKERFILE="src/PublicApi/Dockerfile"

NAME=$(cat /dev/urandom | env LC_ALL=C tr -dc 'a-z' | fold -w 8 | head -n 1)
NN=$(echo $RANDOM | fold -w 3 | head -n 1)

RG_NAME="rg-${NAME}-${NN}"
az group create --resource-group "${RG_NAME}" --location "${LOCATION}"

CR_NAME="cr${NAME}${NN}"
az acr create --resource-group "${RG_NAME}" --location "${LOCATION}" --name "${CR_NAME}" --sku Basic

git clone "${APP_REPO}" "_app"
pushd "_app"
git checkout "${APP_COMMIT}"
az acr build --image "${APP_API_NAME}:${APP_COMMIT}" --registry "${CR_NAME}" --file "${APP_API_DOCKERFILE}" .
az acr build --image "${APP_WEB_NAME}:${APP_COMMIT}" --registry "${CR_NAME}" --file "${APP_WEB_DOCKERFILE}" .
popd
rm -r -f "_app"