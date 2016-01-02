#!/bin/bash

IMAGE_NAME="database.kmatzen.com:5000/bkovacs_opensurfaces"

# See if we are already running the image
if [ -z "$(docker ps | grep $IMAGE_NAME)" ]; then
	echo "Docker image '$IMAGE_NAME' is not running, exiting..."
	exit
fi

echo "Docker image '$IMAGE_NAME' is running, attaching to celery session..."
IMAGE_ID=$(docker ps | grep $IMAGE_NAME | awk '{print $1}')
docker exec -ti --user=ubuntu $IMAGE_ID script -q -c "tmux attach -t celery" /dev/null
