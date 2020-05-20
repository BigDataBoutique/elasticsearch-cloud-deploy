# gcloud cli sometimes fails if you use it right after the instance has started up
# adding a retry for that case
while true;
do
	export GCP_ZONE="$(gcloud compute instances list --filter="name=('"$HOSTNAME"')" --format "value(zone)")"
	if [ "$GCP_ZONE" != "" ]; then
		break
	fi
	echo "Failed to detect GCP_ZONE. Retrying in 5 seconds..."
	sleep 5
done