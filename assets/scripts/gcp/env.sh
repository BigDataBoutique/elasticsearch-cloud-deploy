export GCP_ZONE="$(gcloud compute instances list --filter="name=('"$HOSTNAME"')" --format "value(zone)")"