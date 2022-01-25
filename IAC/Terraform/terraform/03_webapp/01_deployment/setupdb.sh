#/bin/sh

cd ../../../apps/eShopOnWeb/src/Web

dotnet tool install --global dotnet-ef
dotnet restore
dotnet tool restore
dotnet ef database update -c catalogcontext -p ../Infrastructure/Infrastructure.csproj -s Web.csproj
dotnet ef database update -c appidentitydbcontext -p ../Infrastructure/Infrastructure.csproj -s Web.csproj
