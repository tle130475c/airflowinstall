#!/usr/bin/env bash

set -euo pipefail

AIRFLOW_HOME=/home/airflow/airflow

# create virtual environment
mkdir -p $AIRFLOW_HOME
curl -LsSf https://astral.sh/uv/install.sh | sh
(cd $AIRFLOW_HOME; uv venv --python 3.13)
source $AIRFLOW_HOME/.venv/bin/activate

# install apache airflow
AIRFLOW_VERSION=3.1.7
PYTHON_VERSION="$(python -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')"
CONSTRAINT_URL="https://raw.githubusercontent.com/apache/airflow/constraints-${AIRFLOW_VERSION}/constraints-${PYTHON_VERSION}.txt"
uv pip install "apache-airflow[celery,postgres]==${AIRFLOW_VERSION}" --constraint "${CONSTRAINT_URL}"
