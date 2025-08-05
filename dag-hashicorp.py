from airflow import DAG
from airflow.providers.hashicorp.secrets.vault import VaultClient
from airflow.operators.python import PythonOperator
from airflow.models import Variable
from datetime import datetime
import json
import logging

# Connection ID from Airflow UI
VAULT_CONN_ID = "ago-duar-argocd-approle-credentials"
SECRET_PATH = "kv/data/extraction/duar_xld.json"  # Path in Vault

default_args = {
    'start_date': datetime(2025, 8, 1),
    'catchup': False
}

def fetch_vault_secret(**context):
    from airflow.hooks.base import BaseHook

    conn = BaseHook.get_connection(VAULT_CONN_ID)

    # Build the Vault client
    client = VaultClient(
        conn_id=VAULT_CONN_ID
    )

    # Fetch the secret
    secret = client.get_secret(SECRET_PATH)
    logging.info(f"Raw secret fetched: {secret}")

    # Extract the 'data' from Vault KV v2 response
    data = secret.get('data', {}).get('data', {})

    # Push to XCom for next task
    context['ti'].xcom_push(key='secret_data', value=data)

def display_secret(**context):
    data = context['ti'].xcom_pull(key='secret_data')
    logging.info("Fetched Vault Secret Content:")
    logging.info(json.dumps(data, indent=2))


with DAG(
    "test_vault_fetch_duar_xld",
    default_args=default_args,
    schedule_interval=None,
    tags=["vault", "test"],
) as dag:

    fetch_secret = PythonOperator(
        task_id="fetch_secret",
        python_callable=fetch_vault_secret,
        provide_context=True,
    )

    display_secret = PythonOperator(
        task_id="display_secret",
        python_callable=display_secret,
        provide_context=True,
    )

    fetch_secret >> display_secret