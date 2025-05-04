# ----------- STAGE 1: BUILD -----------
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build

# Install dependencies
RUN apt-get update && apt-get install -y git jq

WORKDIR /src

# Clone only the repo we need
RUN git clone --single-branch --depth 1 https://github.com/cforce/azure-search-dotnet-utilities.git

RUN echo 'tmp/dotnet-diagnostic-*' > .dockerignore

# Move into the target project
WORKDIR /src/azure-search-dotnet-utilities/index-backup-restore/v11/AzureSearchBackupRestoreIndex

# Define optional build arguments
ARG SourceSearchServiceName
ARG SourceAdminKey
ARG SourceIndexName
ARG TargetSearchServiceName
ARG TargetAdminKey
ARG TargetIndexName
ARG BackupDirectory=index-backup

ENV SourceSearchServiceName=${SourceSearchServiceName}
ENV SourceAdminKey=${SourceAdminKey}

# Patch the appsettings.json using jq
RUN ls -alh && cat appsettings.json

# Patch appsettings.json using jq with external filter
RUN echo '\
  if $sssn != "" then .SourceSearchServiceName = $sssn else . end | \
  if $sak != "" then .SourceAdminKey = $sak else . end | \
  if $sin != "" then .SourceIndexName = $sin else . end | \
  if $tssn != "" then .TargetSearchServiceName = $tssn else . end | \
  if $tak != "" then .TargetAdminKey = $tak else . end | \
  if $tin != "" then .TargetIndexName = $tin else . end | \
  if $bd != "" then .BackupDirectory = $bd else . end' \
  > /tmp/jq_filter.jq && \
  jq \
    --arg sssn "${SourceSearchServiceName}" \
    --arg sak "${SourceAdminKey}" \
    --arg sin "${SourceIndexName}" \
    --arg tssn "${TargetSearchServiceName}" \
    --arg tak "${TargetAdminKey}" \
    --arg tin "${TargetIndexName}" \
    --arg bd "${BackupDirectory}" \
    -f /tmp/jq_filter.jq \
    appsettings.json > appsettings.patched.json && \
  mv appsettings.patched.json appsettings.json && \
  rm /tmp/jq_filter.jq


# Restore, build, and publish
RUN dotnet restore ../AzureSearchBackupRestoreIndex.sln
RUN dotnet publish ./AzureSearchBackupRestoreIndex.csproj -c Release -o /out --no-restore

# ----------- STAGE 2: RUNTIME -----------
FROM mcr.microsoft.com/dotnet/aspnet:8.0

WORKDIR /app

# Copy only the built output and config
COPY --from=build /out ./
COPY --from=build /src/azure-search-dotnet-utilities/index-backup-restore/v11/AzureSearchBackupRestoreIndex/appsettings.json .

# Allow mounting local backup directory
VOLUME /app/index-backup

# Entry point runs the utility
ENTRYPOINT ["dotnet", "AzureSearchBackupRestoreIndex.dll"]

