#!/bin/sh

export SourceSearchServiceName="XXXXXXXXX"
export TargetSearchServiceName="YYYYYYYYY"
#export SourceAdminKey="your-source-admin-key"  # Replace with actual key
#export TargetAdminKey="your-target-admin-key"  # Replace with actual key
export SourceIndexName="AAAAAA"
export TargetIndexName="AAAAAA-bk"
export BackupDirectory="index-backup"

podman build -t azure-search-utilities \
  --build-arg SourceSearchServiceName="$SourceSearchServiceName" \
  --build-arg SourceAdminKey="$SourceAdminKey" \
  --build-arg SourceIndexName="$SourceIndexName" \
  --build-arg TargetSearchServiceName="$TargetSearchServiceName" \
  --build-arg TargetAdminKey="$TargetAdminKey" \
  --build-arg TargetIndexName="$TargetIndexName" \
  --build-arg BackupDirectory="$BackupDirectmkdir -p index-backupory" .

# Check if SourceAdminKey and TargetAdminKey are set and not empty
if [ -z "$SourceAdminKey" ] || [ -z "$TargetAdminKey" ]; then
  echo "Error: Both SourceAdminKey and TargetAdminKey must be set and not empty."
  exit 1
fi
mkdir -p index-backup

podman run --rm \
  -e SourceSearchServiceName \
  -e SourceAdminKey \
  -e TargetSearchServiceName \
  -e TargetAdminKey \
  -v "$(pwd)/index-backup:/app/index-backup" \
  localhost/azure-search-utilities