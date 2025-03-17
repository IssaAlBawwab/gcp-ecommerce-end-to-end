PRODUCER_IMAGE_NAME=ecommerce-producer-image
PRODUCER_CONTAINER_NAME=ecommerce-producer-container
PRODUCER_DOCKERFILE=producer/Dockerfile.producer

PRODUCER_FAST_IMAGE_NAME=ecommerce-producer-fast-image
PRODUCER_FAST_CONTAINER_NAME=ecommerce-producer-fast-container
PRODUCER_FAST_DOCKERFILE=producer/Dockerfile.producer_fast

CONSUMER_IMAGE_NAME=ecommerce-consumer-image
CONSUMER_CONTAINER_NAME=ecommerce-consumer-container
CONSUMER_DOCKERFILE=consumer/Dockerfile.consumer

DBT_PROJECT_DIR=dbt/ecommerce_dbt

CONFIG_FILE=confluent_cluster_api.txt
DATA_ZIP_URL=https://www.kaggle.com/api/v1/datasets/download/mkechinov/ecommerce-events-history-in-electronics-store
DATA_ZIP_FILE=ecommerce-events-history-in-electronics-store.zip
DATA_DIR=ecommerce-events-history-in-electronics-store
CSV_FILE_NAME=events.csv
CSV_FILE_CONTAINER_PATH=/app/ecommerce-events-history-in-electronics-store/events.csv


ask-project-id:
	@echo "Please enter your GCP Project ID:"; \
	read -r PROJECT_ID; \
	export DBT_DATABASE=$$PROJECT_ID

download-data:
	curl -L -o $(DATA_ZIP_FILE) $(DATA_ZIP_URL)
	unzip -o -j $(DATA_ZIP_FILE) -d ecommerce-events-history-in-electronics-store

build-producer: download-data
	docker build -f $(PRODUCER_DOCKERFILE) -t $(PRODUCER_IMAGE_NAME) .

run-producer: build-producer
	docker run --name "$(PRODUCER_CONTAINER_NAME)" "$(PRODUCER_IMAGE_NAME)"

build-producer-fast: download-data
	docker build -f $(PRODUCER_FAST_DOCKERFILE) -t $(PRODUCER_FAST_IMAGE_NAME) .

run-producer-fast: build-producer-fast
	docker run --name "$(PRODUCER_FAST_CONTAINER_NAME)" "$(PRODUCER_FAST_IMAGE_NAME)"

stop-producer:
	docker stop $(PRODUCER_CONTAINER_NAME) || true
	docker rm $(PRODUCER_CONTAINER_NAME) || true

stop-producer-fast:
	docker stop $(PRODUCER_FAST_CONTAINER_NAME) || true
	docker rm $(PRODUCER_FAST_CONTAINER_NAME) || true

build-consumer:
	docker build -f $(CONSUMER_DOCKERFILE) -t $(CONSUMER_IMAGE_NAME) .

run-consumer: build-consumer
	docker run --name "$(CONSUMER_CONTAINER_NAME)" "$(CONSUMER_IMAGE_NAME)"

stop-consumer:
	docker stop $(CONSUMER_CONTAINER_NAME) || true
	docker rm $(CONSUMER_CONTAINER_NAME) || true



dbt-run: ask-project-id
	cd $(DBT_PROJECT_DIR) && dbt run --vars '{"DBT_DATABASE": "$(DBT_DATABASE)"}'

dbt-build: ask-project-id
	cd $(DBT_PROJECT_DIR) && dbt build --vars '{"DBT_DATABASE": "$(DBT_DATABASE)"}'

dbt-test: ask-project-id
	cd $(DBT_PROJECT_DIR) && dbt test --vars '{"DBT_DATABASE": "$(DBT_DATABASE)"}'

dbt-docs-generate: ask-project-id
	cd $(DBT_PROJECT_DIR) && dbt docs generate


clean: stop-producer stop-consumer dbt-clean stop-producer-fast
	docker image rm $(PRODUCER_IMAGE_NAME) || true
	docker image rm $(PRODUCER_FAST_IMAGE_NAME) || true
	docker image rm $(CONSUMER_IMAGE_NAME) || true
	rm -rf $(DATA_ZIP_FILE) $(DATA_DIR)

help:
	@echo "Makefile for ecommerce producer, consumer, and dbt applications"
	@echo ""
	@echo "Usage:"
	@echo "  make download-data   - Download and extract e-commerce events data"
	@echo "  make build-producer  - Build the Docker image for the producer (downloads data if needed)"
	@echo "  make run-producer    - Run the Docker container for the producer (builds image if necessary)"
	@echo "  make stop-producer   - Stop and remove the producer Docker container"
	@echo "  make build-producer-fast  - Build the Docker image for the producer-fast (downloads data if needed)"
	@echo "  make run-producer-fast    - Run the Docker container for the producer-fast (builds image if necessary)"
	@echo "  make stop-producer-fast   - Stop and remove the producer-fast Docker container"
	@echo "  make build-consumer  - Build the Docker image for the consumer"
	@echo "  make run-consumer    - Run the Docker container for the consumer"
	@echo "  make stop-consumer   - Stop and remove the consumer Docker container"
	@echo "  make dbt-run         - Run the dbt transformations (prompts for GCP Project ID)"
	@echo "  make dbt-build       - Run the dbt build process (prompts for GCP Project ID)"
	@echo "  make dbt-test        - Run the dbt tests (prompts for GCP Project ID)"
	@echo "  make dbt-clean       - Clean the dbt project (remove target directory)"
	@echo "  make dbt-docs-generate - Generate the dbt documentation (prompts for GCP Project ID)"
	@echo "  make dbt-docs-serve  - Serve the dbt documentation locally"
	@echo "  make clean          - Stop all containers, remove their images, and clean dbt project and data files"
	@echo ""
	@echo "Configuration:"
	@echo "  1. Download your Confluent Cloud API configuration file and save it as '$(CONFIG_FILE)'"
	@echo "     in the same directory as the Dockerfile (project root)."
	@echo "  2. Run 'make run-producer' to start the ecommerce producer."
	@echo "  3. Ensure your consumer application is configured to connect to your Confluent Cloud Kafka instance."
	@echo "  4. Ensure you have set up your dbt project in the '$(DBT_PROJECT_DIR)' directory."
	@echo "  5. When running dbt commands, you will be prompted to enter your GCP Project ID."
	@echo ""