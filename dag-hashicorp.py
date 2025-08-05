from airflow import DAG
from airflow.hooks.base import BaseHook
from airflow.operators.python import PythonOperator
from datetime import datetime
import hvac
import logging
import json

VAULT_CONN_ID = "ago-duar-argocd-approle-credentials"
VAULT_SECRET_PATH = "kv/data/extraction/duar_xld.json"

def fetch_from_vault(**context):
    conn = BaseHook.get_connection(VAULT_CONN_ID)

    vault_url = conn.host
    role_id = conn.login
    secret_id = conn.password
    mount_point = conn.extra_dejson.get("auth_mount_point", "approle")
    kv_version = int(conn.extra_dejson.get("kv_engine_version", 2))

    client = hvac.Client(url=vault_url)
    client.auth_approle(role_id=role_id, secret_id=secret_id, mount_point=mount_point)

    # Fetch the secret
    secret = client.secrets.kv.v2.read_secret_version(
        path="extraction/duar_xld.json",
        mount_point="kv"
    )
    
    data = secret['data']['data']
    logging.info("Vault secret contents:")
    logging.info(json.dumps(data, indent=2))

    # Push to XCom
    context['ti'].xcom_push(key='secret_data', value=data)

def display_secret(**context):
    data = context['ti'].xcom_pull(key='secret_data')
    logging.info("Displaying Vault secret:")
    logging.info(json.dumps(data, indent=2))


with DAG(
    "vault_fetch_test_duar_xld",
    start_date=datetime(2025, 8, 1),
    schedule_interval=None,
    catchup=False,
    tags=["vault", "test"]
) as dag:

    fetch_secret = PythonOperator(
        task_id="fetch_secret",
        python_callable=fetch_from_vault,
        provide_context=True,
    )

    log_secret = PythonOperator(
        task_id="log_secret",
        python_callable=display_secret,
        provide_context=True,
    )

    fetch_secret >> log_secret