def read_confluent_cloud_config(config_file_path):
    """
    Reads Confluent Cloud configuration from a text file and extracts
    API Key, API Secret, and Bootstrap URL.

    Args:
        config_file_path (str): Path to the cloud-config.txt file.

    Returns:
        dict: A dict containing (api_key, api_secret, bootstrap_url)
    """
    config = {}
    with open(config_file_path, 'r') as file:
        try:
            text = file.read()
            text=text.split('\n')
            config['key'] = text[3]
            config['secret'] = text[6]
            config['cluster_id'] = text[9]
            config['bootstrap'] = text[12]
        except Exception as e:
            print(f"couldnt read file because: {e}")
            return None
    return config