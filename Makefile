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
	unzip -o -j $(DATA_ZIP_FILE) -d $(DATA_DIR)

build-producer: download-data
	docker build -f $(PRODUCER_DOCKERFILE) -t $(PRODUCER_IMAGE_NAME) .

run-producer: build-producer
	docker run --rm --name "$(PRODUCER_CONTAINER_NAME)" -it $(PRODUCER_IMAGE_NAME)

build-producer-fast: download-data
	docker build -f $(PRODUCER_FAST_DOCKERFILE) -t $(PRODUCER_FAST_IMAGE_NAME) .

run-producer-fast: build-producer-fast
	docker run --rm --name "$(PRODUCER_FAST_CONTAINER_NAME)" -it $(PRODUCER_FAST_IMAGE_NAME)

stop-and-remove:
	docker stop $(PRODUCER_CONTAINER_NAME) 2>/dev/null || true
	docker rm $(PRODUCER_CONTAINER_NAME) 2>/dev/null || true
	docker stop $(PRODUCER_FAST_CONTAINER_NAME) 2>/dev/null || true
	docker rm $(PRODUCER_FAST_CONTAINER_NAME) 2>/dev/null || true
	docker stop $(CONSUMER_CONTAINER_NAME) 2>/dev/null || true
	docker rm $(CONSUMER_CONTAINER_NAME) 2>/dev/null || true


build-consumer:
	docker build -f $(CONSUMER_DOCKERFILE) -t $(CONSUMER_IMAGE_NAME) .

run-consumer: build-consumer
	docker run --rm --name "$(CONSUMER_CONTAINER_NAME)" -it $(CONSUMER_IMAGE_NAME)

run-consumer-detached: build-consumer
	docker run --name "$(CONSUMER_CONTAINER_NAME)" -d $(CONSUMER_IMAGE_NAME)

attach-consumer-logs:
	docker logs -f "$(CONSUMER_CONTAINER_NAME)"

run-producer-after-consumer: run-consumer-detached build-producer
	docker run --rm --name "$(PRODUCER_CONTAINER_NAME)" -it $(PRODUCER_IMAGE_NAME)

dbt-create-profile:
	@echo "Please enter your GCP Project ID:"; \
	read -r PROJECT_ID; \
	echo "You entered: $$PROJECT_ID"; \
	mkdir -p ~/.dbt; \
	echo "ecommerce_dbt:" > ~/.dbt/profiles.yml; \
	echo " outputs:" >> ~/.dbt/profiles.yml; \
	echo "   dev:" >> ~/.dbt/profiles.yml; \
	echo "     dataset: ecom_events" >> ~/.dbt/profiles.yml; \
	echo "     job_execution_timeout_seconds: 300" >> ~/.dbt/profiles.yml; \
	echo "     job_retries: 1" >> ~/.dbt/profiles.yml; \
	echo "     keyfile: ../../gcp_key.json" >> ~/.dbt/profiles.yml; \
	echo "     method: service-account" >> ~/.dbt/profiles.yml; \
	echo "     priority: interactive" >> ~/.dbt/profiles.yml; \
	echo "     project: $$PROJECT_ID" >> ~/.dbt/profiles.yml; \
	echo "     threads: 1" >> ~/.dbt/profiles.yml; \
	echo "     type: bigquery" >> ~/.dbt/profiles.yml; \
	echo " target: dev" >> ~/.dbt/profiles.yml; \
	echo "dbt profile created at ~/.dbt/profiles.yml with your Project ID."

dbt-run: ask-project-id
	cd $(DBT_PROJECT_DIR) && dbt run --vars '{"DBT_DATABASE": "$(DBT_DATABASE)"}'

dbt-build: ask-project-id
	cd $(DBT_PROJECT_DIR) && dbt build --vars '{"DBT_DATABASE": "$(DBT_DATABASE)"}'

dbt-test: ask-project-id
	cd $(DBT_PROJECT_DIR) && dbt test --vars '{"DBT_DATABASE": "$(DBT_DATABASE)"}'

dbt-docs-generate: ask-project-id
	cd $(DBT_PROJECT_DIR) && dbt docs generate

dbt-clean:
	cd $(DBT_PROJECT_DIR) && dbt clean

clean: stop-and-remove dbt-clean
	docker image rm $(PRODUCER_IMAGE_NAME) 2>/dev/null || true
	docker image rm $(PRODUCER_FAST_IMAGE_NAME) 2>/dev/null || true
	docker image rm $(CONSUMER_IMAGE_NAME) 2>/dev/null || true
	rm -rf $(DATA_ZIP_FILE) $(DATA_DIR)

help:
	@echo "Makefile for ecommerce producer, consumer, and dbt applications"
	@echo ""
	@echo "Usage:"
	@echo "  make download-data	 - Download and extract e-commerce events data"
	@echo "  make build-producer	 - Build the Docker image for the producer (downloads data if needed)"
	@echo "  make run-producer	 - Run the Docker container for the producer (builds image if necessary)"
	@echo "  make stop-and-remove	 - Stop and remove all containers"
	@echo "  make build-producer-fast	 - Build the Docker image for the producer-fast (downloads data if needed)"
	@echo "  make run-producer-fast	 - Run the Docker container for the producer-fast (builds image if necessary)"
	@echo "  make build-consumer	 - Build the Docker image for the consumer"
	@echo "  make run-consumer	 - Run the Docker container for the consumer"
	@echo "  make dbt-create-profile	 - Create the dbt profiles.yml (prompts for GCP Project ID)"
	@echo "  make dbt-run		 - Run the dbt transformations (creates profile if needed, prompts for GCP Project ID)"
	@echo "  make dbt-build		 - Run the dbt build process (creates profile if needed, prompts for GCP Project ID)"
	@echo "  make dbt-test		 - Run the dbt tests (creates profile if needed, prompts for GCP Project ID)"
	@echo "  make dbt-clean		 - Clean the dbt project (remove target directory)"
	@echo "  make dbt-docs-generate	 - Generate the dbt documentation (creates profile if needed, prompts for GCP Project ID)"
	@echo "  make dbt-docs-serve	 - Serve the dbt documentation locally"
	@echo "  make clean		 - Stop all containers, remove their images, and clean dbt project and data files"
	@echo ""
	@echo "Configuration:"
	@echo "  1. Download your Confluent Cloud API configuration file and save it as '$(CONFIG_FILE)'"
	@echo "     in the same directory as the Dockerfile (project root)."
	@echo "  2. Run 'make run-producer' to start the ecommerce producer."
	@echo "  3. Ensure your consumer application is configured to connect to your Confluent Cloud Kafka instance."
	@echo "  4. Ensure you have set up your dbt project in the '$(DBT_PROJECT_DIR)' directory."
	@echo "  5. When running dbt commands, you will be prompted to enter your GCP Project ID."
	@echo ""