# GCP E-commerce Event Pipeline

This project implements an end-to-end data pipeline for processing e-commerce events, leveraging Google Cloud Platform (GCP) services, Confluent Kafka, Docker, and other tools.

![Data Flow](images/flow1.png)

## Overview

The pipeline ingests e-commerce event data, streams it through Confluent Cloud Kafka, stores it in Google BigQuery, transforms it using dbt, and finally makes it available for analysis and visualization via Looker Studio.

## Data Used (No need to download it, the scripts will automatically do that)
* https://www.kaggle.com/datasets/mkechinov/ecommerce-events-history-in-electronics-store

## Architecture

The project follows these stages:

1.  **Data Source:** E-commerce event data is initially sourced from a CSV file.
2.  **Producer:** A Python application, containerized with Docker, reads the e-commerce event data from the CSV file and produces it as a real-time stream to a topic named `ecom_events` in Confluent Cloud Kafka.
3.  **Confluent Cloud Kafka:** This managed Kafka service acts as the central message broker, decoupling the producer and consumer.
4.  **Consumer:** A Python application, also containerized with Docker, consumes the events from the `ecom_events` Kafka topic.
5.  **Google BigQuery (Source Table):** The consumer directly ingests the raw event data into a BigQuery table named `kafka_ecom_events`. Basic transformations applied at this stage.
6.  **dbt (Data Build Tool):** dbt is used to perform more complex transformations on the data within BigQuery, creating staging and core tables for analytical purposes.
7.  **Google BigQuery (Transformed Tables):** The transformed data resides in various tables within BigQuery, ready for querying.
8.  **Analytical Dashboards:** Tools like Looker Studio can connect to the transformed BigQuery tables to create insightful dashboards and reports.

## BigQuery Table Design Decisions

The BigQuery `kafka_ecom_events` table is designed with performance and cost-efficiency for analytical queries in mind. We've implemented the following partitioning and clustering strategy:

* **Partitioning by `event_time`:** The table is partitioned by the `event_time` column on a daily basis. This is a crucial decision as most analytical queries on e-commerce data involve filtering by specific time ranges (e.g., daily, weekly, monthly reports). Partitioning allows BigQuery to only scan the relevant partitions, significantly reducing query costs and improving performance.

* **Clustering by `event_type`, `product_id`, and `category_code`:** We've chosen to cluster the data by these three fields. This is based on the expectation that common analytical queries will involve filtering or aggregating data based on the type of event (e.g., purchases, views), specific products, or product categories. Clustering co-locates data with similar values for these columns within each partition, further enhancing query performance.

* **Kafka Partition Key (`user_id`):** While the Kafka topic is partitioned by `user_id` (which is useful for ensuring message ordering per user within Kafka), we opted not to use `user_id` as the primary partitioning or clustering key in BigQuery. This is because our anticipated analytical queries are more likely to focus on time-based analysis and aggregations across different event types, products, and categories, rather than primarily filtering by individual users. We can still efficiently query data based on `user_id` in BigQuery using standard SQL filtering.


## Technologies Used

* **Python:** For developing the producer and consumer applications.
* **Confluent Kafka:** A distributed streaming platform for message queuing.
* **Google Cloud Platform (GCP):** The cloud environment hosting the project.
    * **BigQuery:** For data warehousing and analytics.
* **Docker:** For containerizing the producer and consumer applications.
* **dbt (data build tool):** For performing data transformations in BigQuery.
* **Make:** For automating build and deployment tasks.
* **Terraform:** For defining and managing the infrastructure on GCP.
* **Looker Studio (example):** For creating analytical dashboards.

## Running the Applications
* Note: "producer-fast" is only for quickly producing all the data at once, <br>in a real environment the data will be produced around the rate of "producer"
<br><br>You can use the `Makefile` to simplify common tasks:

* `make download-data`: Download and extract the initial e-commerce events data (if needed for local testing).
* `make build-producer`: Build the Docker image for the producer.
* `make run-producer`: Run the Docker container for the producer.
* `make stop-and-remove`: Stop and remove all containers.
* `make build-producer-fast`: Build the Docker image for the producer-fast (downloads data if needed).
* `make run-producer-fast`: Run the Docker container for the producer-fast (builds image if necessary).
* `make build-consumer`: Build the Docker image for the consumer.
* `make run-consumer`: Run the Docker container for the consumer.
* `make dbt-run`: Run the dbt transformations (prompts for GCP Project ID and passes it as a variable).
* `make dbt-build`: Run the dbt build process (prompts for GCP Project ID and passes it as a variable).
* `make dbt-test`: Run the dbt tests (prompts for GCP Project ID and passes it as a variable).
* `make dbt-clean`: Clean the dbt project (remove the `target` directory).
* `make dbt-docs-generate`: Generate the dbt documentation (prompts for GCP Project ID).
* `make clean`: Stop all containers, remove their images, and clean dbt project and data files.
* `make help`: Display a list of available `make` commands.

## BigQuery Schema (`kafka_ecom_events` Table)

The `kafka_ecom_events` table in BigQuery has the following schema:

| Field Name     | Type      | Mode     | Description (Optional) |
| -------------- | --------- | -------- | ---------------------- |
| `event_time`   | TIMESTAMP | NULLABLE | Timestamp of the event. |
| `event_type`   | STRING    | NULLABLE | Type of the e-commerce event (e.g., purchase, view). |
| `product_id`   | STRING    | NULLABLE | Identifier of the product. |
| `category_id`  | STRING    | NULLABLE | Identifier of the product category. |
| `category_code`| STRING    | NULLABLE | Code representing the product category. |
| `brand`        | STRING    | NULLABLE | Brand of the product. |
| `price`        | FLOAT     | NULLABLE | Price of the product. |
| `user_id`      | STRING    | NULLABLE | Identifier of the user. |
| `user_session` | STRING    | NULLABLE | Identifier of the user's session. |
## Dashboard
* https://lookerstudio.google.com/reporting/56d74565-dc30-4f66-9a11-c9cc01d82686
* Incase the link stops working since I will probably delete the data in bigquery
* ![alt text](images/dashboard1.png)
* ![alt text](images/dashboard2.png)
* ![alt text](images/dashboard3.png)

## Configuration
### Confluent
1. Create Confluent Cluster
    - ![alt text](images/cluster1.png)
    - ![alt text](images/cluster2.png)
    - ![alt text](images/cluster3.png)
    - ![alt text](images/image.png)

2. Create api key
    - ![alt text](images/clusterkey.png)
    - ![alt text](images/clusterkey2.png)
    - ![alt text](images/clusterkey3.png)
    -  Important : Rename key to "confluent_cluster_api.txt"

3. Create topic
    - ![alt text](images/topic.png)
    - Name it "ecom_events" 
    - ![alt text](images/topic2.png)

### Google Cloud
0. Create Project
    - ![alt text](images/gcpproject.png)

1. Enable the following apis
    - ![alt text](images/computeapi.png)
    - ![alt text](images/bigqueryapi.png)
    - ![alt text](images/storageapi.png)

2. Create Service account
    - ![alt text](images/service.png)
    - ![alt text](images/service2.png)
    - Hit "done"
    - ![alt text](images/service3.png)
    - Click "Manage Keys"
    - ![alt text](images/service4.png)
    - Click "Create new key" and then choose "JSON"
    - Important: Rename it to "gcp_key.json"

* **Confluent Cloud:** The producer and consumer applications rely on a Confluent Cloud API configuration file (`confluent_cluster_api.txt`) for connecting to your Kafka cluster. Ensure this file is placed in the project root.
* **GCP Credentials:** The consumer application uses a GCP service account key file (`gcp_key.json`) to authenticate with Google BigQuery. Ensure this file is placed in the project root (exercise caution when handling this file and avoid committing it to public repositories).

### Terraform
1. Install terraform on your machine follow guide https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli 
2. git clone https://github.com/IssaAlBawwab/gcp-ecommerce-end-to-end.git
3. Make sure gcp_key.json and confluent_cluster_api.txt are in the project root
4. cd terraform/
5. terraform apply 
6. enter gcp project id (get it from here copy "ID" not the name)
    - ![alt text](images/gcpid.png)
7. enter "yes"
8. ![alt text](images/terraform1.png)

## Setup
### enter VM
* ![alt text](images/entervm.png)
* click "SSH"
### After you configured everything above
0. sudo apt update
1. git clone https://github.com/IssaAlBawwab/gcp-ecommerce-end-to-end.git
2. upload keys (sometimes this glitches and it prompts you to retry so do that and reupload and it should work)
    - ![alt text](images/upload_keys.png)
3. mv gcp_key.json gcp-ecommerce-end-to-end/
4. mv confluent_cluster_api.txt  gcp-ecommerce-end-to-end/
5. cd gcp-ecommerce-end-to-end
6. sudo apt install make
7. sudo apt-get install -y unzip
8. install docker with the following
```
# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```
8. sudo usermod -aG docker $USER
9. close the vm ssh window, then reopen it, this is to make the group change effect we did to take place
10. ```
    cd gcp-ecommerce-end-to-end
    make run-producer-fast
    ```
11. Should see this 
    - ![alt text](images/run-prodcuer-fast.png)

12. Should see the messages sent to confluent 
    - ![alt text](images/confluent-messages.png)

13. make run-consumer
14. Should see this
    - ![alt text](images/consumer-progress.png)
    - wait till it finishes then click CTRL-C

15. ```
    sudo apt install python3-venv
    python3 -m venv dbt_venv
    source dbt_venv/bin/activate
    pip install dbt-core dbt-bigquery    
    ```

16. run "make dbt-create-profile" and insert your project id

17. make dbt-run and insert your project id
    - should see this after
    - ![alt text](images/dbt-run.png)
18. Congrats now you should have these tables
    - ![alt text](images/tables.png)
---
