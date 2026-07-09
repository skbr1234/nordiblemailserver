#!/bin/bash
set -e

# Wait for MinIO to be ready
echo "Waiting for MinIO..."
until mc alias set local http://minio:9000 minioadmin minioadmin 2>/dev/null; do
  sleep 1
done

# Create the nordiblemailserver bucket
mc mb local/nordiblemailserver --ignore-existing
echo "MinIO bucket 'nordiblemailserver' created."
