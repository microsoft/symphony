#/bin/sh

cd ../../../apps/eShopOnWeb/src/Web

template=$(cat "appsettings.json")
script=$(echo "${template}" | sed 's~__CATALOGDBCS__~'"${CATALOGDBCS}"'~' | sed 's~__IDENTITYDBCS__~'"${IDENTITYDBCS}"'~')
echo "${script}" > "appsettings.json"
