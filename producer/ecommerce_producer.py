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
    with open(data_path, 'r', newline='', encoding='utf-8') as file:
        input_file_iter = csv.DictReader(file)
        for event in input_file_iter:
            yield event


def delivery_report(err, msg):
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
        # Linger.ms:  Wait for up to 10ms for more messages to accumulate in the buffer.
        'linger.ms': 1,  # Very important for batching!
        # Batch size: Try to send batches of up to 16KB.
        'batch.size': 8192,
        'acks': '1', # Wait all insync replicas to ack the message.
    }

    producer = Producer(producer_config)

    topic_name = "ecom_events"
    data_path = 'ecommerce-events-history-in-electronics-store/events.csv'
    event_data = generate_ecommerce_event(data_path)
    count = 0
    try:
        for event in event_data:
            logger.info(f"Producing event: {event}")
            message_payload = json.dumps(event).encode('utf-8')
            user_id_key = str(event.get('user_id')).encode('utf-8')
            producer.produce(
                topic_name, key=user_id_key, value=message_payload, callback=delivery_report
            )
            count += 1
            # Give the producer time to send messages.  CRUCIAL CHANGE!
            producer.poll(0.05)

        logger.info("Finished reading events.  Flushing remaining messages...")
        producer.flush()
        logger.info(f"Sent {count} messages")

    except KeyboardInterrupt:
        logger.info("Producer application stopped by user.")

        producer.flush()
    except Exception as e:
        logger.error(f"An error occurred: {e}", exc_info=True)

        producer.flush()
    finally:
        logger.info("Producer flushed and closed.")