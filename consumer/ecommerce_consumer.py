import json
from confluent_kafka import Consumer, KafkaError
from google.cloud import bigquery
import os
import logging
from utils import read_confluent_cloud_config

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

if __name__ == '__main__':

    config_file_path = os.environ.get("CONFIG_FILE_PATH", "confluent_cluster_api.txt")
    ccloud_config = read_confluent_cloud_config(config_file_path)
    if ccloud_config is None:
        logger.error("Confluent Cloud configuration could not be loaded. Exiting.")
        exit(1)

    consumer_config = {
        'bootstrap.servers': ccloud_config.get('bootstrap'),
        'security.protocol': 'SASL_SSL',
        'sasl.mechanisms': 'PLAIN',
        'sasl.username': ccloud_config.get('key'),
        'sasl.password': ccloud_config.get('secret'),
        'group.id': 'python_ecommerce_consumer_group',
        'auto.offset.reset': 'latest'
    }

    try:
        with open('gcp_key.json', 'r') as file:
            gcp_creds = json.load(file)
        project_id = gcp_creds['project_id']
        dataset_id = "ecom_events"
        table_id = "kafka_ecom_events"

        topic_name = "ecom_events"

        consumer = Consumer(consumer_config)

        consumer.subscribe([topic_name])

        client = bigquery.Client(project=project_id)
        table_ref = client.dataset(dataset_id).table(table_id)
        table = client.get_table(table_ref)

        logger.info(f"Consumer subscribing to topic '{topic_name}'...")
        batch_size = 10000  
        rows_to_insert = []
        poll_timeout = 0.1  

        while True:
            msg = consumer.poll(poll_timeout)

            if msg is None:
                if rows_to_insert:  
                    errors = client.insert_rows_json(table, rows_to_insert)
                    if errors == []:
                        logger.info(f"Successfully inserted {len(rows_to_insert)} row(s) into BigQuery.")
                    else:
                        logger.error(f"Errors encountered while inserting rows into BigQuery: {errors}")
                        for error in errors:
                            logger.error(f"BigQuery Insert Error: {error['errors']}")
                    rows_to_insert = []
                continue
            if msg.error():
                if msg.error().code() == KafkaError._PARTITION_EOF:
                    continue
                else:
                    logger.error(f"Error receiving message: {msg.error()}")
                    break

            else:
                try:
                    event_data = json.loads(msg.value().decode('utf-8'))
                    logger.debug(f"Received event: {event_data}")  

                    if event_data.get('brand') == 'null':
                        event_data['brand'] = None

                    if event_data.get('category_code') == 'null':
                        event_data['category_code'] = None

                    rows_to_insert.append(event_data)

                    if len(rows_to_insert) >= batch_size:
                        errors = client.insert_rows_json(table, rows_to_insert)
                        if errors == []:
                            logger.info(f"Successfully inserted {len(rows_to_insert)} row(s) into BigQuery.")
                        else:
                            logger.error(f"Errors encountered while inserting rows into BigQuery: {errors}")
                            for error in errors:
                                logger.error(f"BigQuery Insert Error: {error['errors']}")
                        rows_to_insert = []  

                except json.JSONDecodeError as e:
                    logger.error(f"Error decoding JSON from Kafka message: {e}")
                except Exception as e:
                    logger.error(f"An unexpected error occurred during message processing: {e}", exc_info=True)

    except KeyboardInterrupt:
        logger.info("Consumer application stopped by user.")
    except Exception as e:
        logger.error(f"An error occurred during consumer setup or operation: {e}", exc_info=True)
    finally:
        if rows_to_insert:  
            errors = client.insert_rows_json(table, rows_to_insert)
            if errors == []:
                logger.info(f"Successfully inserted {len(rows_to_insert)} remaining row(s) into BigQuery.")
            else:
                logger.error(f"Errors encountered while inserting remaining rows into BigQuery: {errors}")
                for error in errors:
                    logger.error(f"BigQuery Insert Error: {error['errors']}")
        consumer.close()
        logger.info("Consumer closed.")