from confluent_kafka import Producer
import json
import csv
import os
import logging
import multiprocessing
from utils import read_confluent_cloud_config
import tempfile
import shutil

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)


def delivery_report_local(err, msg):
    """Local delivery report, less verbose."""
    if err:
        logger.error(f"Message delivery failed: {err}")


def produce_events(data_path, config, topic_name):
    """
    Producer function to be run in a separate process.  Now takes the path to a *split* file.
    """
    producer = Producer(config)
    count = 0

    try:
        with open(data_path, 'r', newline='', encoding='utf-8') as file:
            reader = csv.DictReader(file)
            for event in reader:
                message_payload = json.dumps(event).encode('utf-8')
                user_id_key = str(event.get('user_id')).encode('utf-8')
                producer.produce(topic_name, key=user_id_key, value=message_payload,
                                 callback=delivery_report_local)
                count += 1
                producer.poll(0)

    except Exception as e:
        logger.error(f"Process for {data_path}: An error occurred: {e}", exc_info=True)
    finally:
        producer.flush()
        logger.info(f"Process for {data_path}: Flushed and closed. Sent {count} messages.")
 



def split_csv(data_path, num_splits):
    """Splits the CSV file into smaller temporary files.

    Args:
        data_path: Path to the original CSV file.
        num_splits: The number of smaller files to create.

    Returns:
        A list of paths to the temporary files.
    """
    temp_dir = tempfile.mkdtemp() 
    logger.info(f"Created temporary directory: {temp_dir}")
    temp_files = []

    with open(data_path, 'r', newline='', encoding='utf-8') as infile:
        reader = csv.reader(infile)
        header = next(reader)

        total_lines = sum(1 for _ in open(data_path, encoding='utf-8')) -1 # -1 don't count header
        lines_per_file = (total_lines + num_splits - 1) // num_splits  # ceiling division


        file_num = 0
        outfile = None
        writer = None

        # rewind the file to process it.
        infile.seek(0)
        reader = csv.reader(infile)
        next(reader) #skip the header

        for i, row in enumerate(reader):
            if i % lines_per_file == 0:
                if outfile:
                    outfile.close()
                file_num += 1
                temp_file_path = os.path.join(temp_dir, f"split_{file_num}.csv")
                temp_files.append(temp_file_path)
                logger.info(f"Creating temporary file: {temp_file_path}")
                outfile = open(temp_file_path, 'w', newline='', encoding='utf-8')
                writer = csv.writer(outfile)
                writer.writerow(header)

            writer.writerow(row)

        if outfile:
            outfile.close()

    return temp_files, temp_dir


def main():
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
        'linger.ms': 1,
        'batch.size': 32768,
        'acks': 1,
        'compression.type': 'snappy',
    }

    topic_name = "ecom_events"
    data_path = 'ecommerce-events-history-in-electronics-store/events.csv'
    num_processes = multiprocessing.cpu_count()  # all available cores
    logger.info(f"Starting {num_processes} producer processes...")

    temp_files, temp_dir = split_csv(data_path, num_processes)

    processes = []
    for temp_file in temp_files:
        p = multiprocessing.Process(target=produce_events, args=(temp_file, producer_config, topic_name))
        processes.append(p)
        p.start()

    for p in processes:
        p.join() 

    shutil.rmtree(temp_dir)
    logger.info(f"Removed temporary directory: {temp_dir}")
    logger.info("All producer processes finished.")


if __name__ == "__main__":
    main()