from confluent_kafka import Producer
import json
import time
import csv
import os
import logging
from utils import read_confluent_cloud_config

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)


def generate_ecommerce_event(data_path):
    """
    Reads e-commerce events from a CSV file and yields each event as a dictionary.

    Args:
        data_path (str): Path to the CSV data file.

    Yields:
        dict: Each e-commerce event as a dictionary.
    """
    with open(data_path, 'r', newline='', encoding='utf-8') as file:
        input_file_iter = csv.DictReader(file)
        for event in input_file_iter:
            yield event


def delivery_report(err, msg):
    """
    Delivery report handler for Kafka Producer.

    This function is asynchronously called by the producer after each message
    has been delivered (or failed to be delivered) to Kafka.

    Args:
        err (KafkaError): An error object if message delivery failed, None if successful.
        msg (Message): The Kafka message that was produced.
    """
    if err:
        logger.error(f"Message delivery failed: {err}")
    else:
        logger.info(
            f"Message delivered to topic '{msg.topic()}' partition [{msg.partition()}] @ offset {msg.offset()}"
        )


if __name__ == "__main__":

    config_file_path = os.environ.get("CONFIG_FILE_PATH", "confluent_cluster_api.txt")
    conf = read_confluent_cloud_config(config_file_path)

    if conf is None:
        logger.error("Confluent Cloud configuration could not be loaded. Exiting.")
        exit(1)

    producer_config = {
        'bootstrap.servers': conf.get('bootstrap'),
        'security.protocol': 'SASL_SSL',
        'sasl.mechanisms': 'PLAIN',
        'sasl.username': conf.get('key'),
        'sasl.password': conf.get('secret'),
    }

    producer = Producer(producer_config)

    topic_name = "ecom_events"
    data_path = 'ecommerce-events-history-in-electronics-store/events.csv'
    event_data = generate_ecommerce_event(data_path)

    try:
        for event in event_data:
            logger.info(f"Producing event: {event}")
            message_payload = json.dumps(event).encode('utf-8')
            user_id_key = str(event.get('user_id')).encode('utf-8')
            producer.produce(
                topic_name, key=user_id_key, value=message_payload, callback=delivery_report
            )
            producer.poll(0)
            time.sleep(1)

    except KeyboardInterrupt:
        logger.info("Producer application stopped by user.") 
    except Exception as e:
        logger.error(f"An error occurred: {e}", exc_info=True) 
    finally:
        producer.flush()
        logger.info("Producer flushed and closed.")