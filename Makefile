PRODUCER_IMAGE_NAME=ecommerce-producer-image
PRODUCER_CONTAINER_NAME=ecommerce-producer-container
CONFIG_FILE=confluent_cluster_api.txt
PRODUCER_DOCKERFILE=producer/Dockerfile.producer
DATA_ZIP_URL=https://www.kaggle.com/api/v1/datasets/download/mkechinov/ecommerce-events-history-in-electronics-store
DATA_ZIP_FILE=ecommerce-events-history-in-electronics-store.zip
DATA_DIR=ecommerce-events-history-in-electronics-store
CSV_FILE_NAME=events.csv
CSV_FILE_CONTAINER_PATH=/app/ecommerce-events-history-in-electronics-store/events.csv


download-data:
	curl -L -o $(DATA_ZIP_FILE) $(DATA_ZIP_URL)
	unzip -o -j $(DATA_ZIP_FILE) -d ecommerce-events-history-in-electronics-store # Corrected unzip command with -j

build-producer: download-data 
	docker build -f $(PRODUCER_DOCKERFILE) -t $(PRODUCER_IMAGE_NAME) .

run-producer: build-producer 
	docker run --name "$(PRODUCER_CONTAINER_NAME)" "$(PRODUCER_IMAGE_NAME)"

stop-producer: 
	docker stop $(PRODUCER_CONTAINER_NAME) || true
	docker rm $(PRODUCER_CONTAINER_NAME) || true

clean: stop-producer 
	docker image rm $(PRODUCER_IMAGE_NAME) || true
	rm -rf $(DATA_ZIP_FILE) $(DATA_DIR)

help:
	@echo "Makefile for ecommerce-producer Docker application"
	@echo ""
	@echo "Usage:"
	@echo "  make download-data   - Download and extract e-commerce events data"
	@echo "  make build-producer  - Build the Docker image for the producer (downloads data if needed)"
	@echo "  make run-producer    - Run the Docker container for the producer (builds image if necessary)"
	@echo "  make stop-producer   - Stop and remove the producer Docker container"
	@echo "  make clean          - Stop producer container, remove producer image, and data files"
	@echo ""
	@echo "Configuration:"
	@echo "  1. Download your Confluent Cloud API configuration file and save it as '$(CONFIG_FILE)'"
	@echo "     in the same directory as the Dockerfile (project root)."
	@echo "  2. Run 'make run-producer' to start the ecommerce producer."
	@echo ""