#!/usr/bin/env bash

set -euo pipefail

mkdir ~/airflow
(cd ~/airflow; uv venv --python 3.13)
source ~/airflow/.venv/bin/activate

AIRFLOW_HOME=~/airflow
AIRFLOW_VERSION=3.1.7
PYTHON_VERSION="$(python -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')"
CONSTRAINT_URL="https://raw.githubusercontent.com/apache/airflow/constraints-${AIRFLOW_VERSION}/constraints-${PYTHON_VERSION}.txt"

# installation
uv pip install "apache-airflow[celery,postgres]==${AIRFLOW_VERSION}" --constraint "${CONSTRAINT_URL}"

# configuration
airflow config list --defaults
cp $AIRFLOW_HOME/airflow.cfg $AIRFLOW_HOME/airflow.cfg.bak
sed -i 's/^load_examples = .*/load_examples = False/' $AIRFLOW_HOME/airflow.cfg
