#!/bin/bash

BASE_PATH="${BASE_PATH:-/opt/MySQLBackup}"

STORAGE_ALIAS="${STORAGE_ALIAS:-mysqlbackup}"
ALIAS_URL="${ALIAS_URL:-https://storage.googleapis.com}"
: "${ACCESS_KEY:?Set ACCESS_KEY for object storage}"
: "${SECRET_KEY:?Set SECRET_KEY for object storage}"
BUCKET_PREFIX="${BUCKET_PREFIX:-backups}"

# Check if the alias exists
if ! mc alias list | grep -q "^$STORAGE_ALIAS "; then
    # If not, create the alias
    mc alias set "$STORAGE_ALIAS" "$ALIAS_URL" "$ACCESS_KEY" "$SECRET_KEY"
    echo "Alias created: $STORAGE_ALIAS"
else
    echo "Alias already exists: $STORAGE_ALIAS"
fi


# Read the number of days to keep backups from the environment variable
DAYS_TO_KEEP=${DAYS_TO_KEEP:-2}
MINIO_BUCKET=${MINIO_BUCKET:-mysqlbackup}
current_date=$(date +"%Y-%m-%d")
yesterday_date=$(date -d "$DAYS_TO_KEEP days ago" +"%Y-%m-%d")

# Read the clusters array from the environment variable
IFS=',' read -r -a CLUSTERS <<< "$CLUSTERS"
IFS=',' read -r -a EXCLUDESCHEMAS <<< "$EXCLUDESCHEMAS"

# Check if the bucket exists
if ! mc ls "${STORAGE_ALIAS}/${BUCKET_PREFIX}/${MINIO_BUCKET}/" &> /dev/null; then
    # If not, create the bucket
    mc mb "${STORAGE_ALIAS}/${BUCKET_PREFIX}/${MINIO_BUCKET}"
    echo "Bucket created: $MINIO_BUCKET"
else
    echo "Bucket already exists: $MINIO_BUCKET"
fi

echo "############################ Starting Backup on $current_date ######################"

# Loop over clusters
for cluster in "${CLUSTERS[@]}"; do

cluster="${cluster}"

# Check if the directory exists
if [ ! -d "$cluster" ]; then
    # If not, create the directory
    mkdir -p "$cluster"
    echo "Directory created: $directory"
else
    echo "Directory already exists: $directory"
fi


  # Loop over databases for the current cluster
  for schema in $(mysql --defaults-extra-file="${BASE_PATH}/dbcreds/${cluster}.cnf" -se 'show databases'); do

    # Skip specific schemas
    case $schema in
      (information_schema|mysql|mysql_innodb_cluster_metadata|performance_schema|sys)
        echo "Skipping backup for ${schema} in ${cluster}."
        continue
        ;;
    esac

        for excludeschema in "${EXCLUDESCHEMAS[@]}"; do
          if [ "$schema" == "$excludeschema" ]; then
            echo "Skipping backup for $schema in $cluster."
            continue
          fi
        done


    # Backup configuration
    current_date=$(date +"%Y-%m-%d")
    yesterday_date=$(date -d "$DAYS_TO_KEEP days ago" +"%Y-%m-%d")
    backup_file="${BASE_PATH}/${cluster}/${schema}_${current_date}.sql"
    previous_backup_file="${schema}_${yesterday_date}.sql.tar.gz"

    echo "Backup of ${schema} in ${cluster} in Progress."

    # Perform mysqldump
    mysqldump --defaults-extra-file="${BASE_PATH}/dbcreds/${cluster}.cnf" --set-gtid-purged=OFF --single-transaction --skip-lock-tables $schema --routines --triggers --events > $backup_file

    # Check the exit status of the mysqldump command
    if [ $? -eq 0 ]; then

      # Using tar with pigz for faster compression
      tar -cf $backup_file.tar.gz --use-compress-program='pigz' --remove-files -C ${BASE_PATH}/${cluster}/ ${schema}_${current_date}.sql
      backup_file=$backup_file.tar.gz
      echo "Backup of ${schema} in ${cluster} completed successfully."

       # Push the backup file to MinIO
       mc cp "$backup_file" "${STORAGE_ALIAS}/${BUCKET_PREFIX}/${MINIO_BUCKET}/${cluster}/"

      echo "Removing ${schema} Previous Backup."
          # Check if the previous backup file exists before removing
          if mc stat "${STORAGE_ALIAS}/${BUCKET_PREFIX}/${MINIO_BUCKET}/${cluster}/$previous_backup_file" &> /dev/null; then
              # If it exists, remove it
              mc rm "${STORAGE_ALIAS}/${BUCKET_PREFIX}/${MINIO_BUCKET}/${cluster}/$previous_backup_file"
              echo "Previous backup file removed: $previous_backup_file"
          else
              echo "Previous backup file not found: $previous_backup_file"
          fi
    else
      echo "Backup of ${schema} in ${cluster} failed."
    fi

  done  # End of inner loop (databases for the current cluster)

done  # End of outer loop (clusters)

echo -e "############################ Backup Completed of $current_date ######################\n\n"

