#!/usr/bin/env bash

set -euo pipefail

# admin user info
ADMIN_USER=admin
ADMIN_FIRSTNAME="<admin_firstname>"
ADMIN_LASTNAME="<admin_lastname>"
ADMIN_EMAIL="<admin_email>"

AIRFLOW_HOME=/home/airflow/airflow
AIRFLOW_USER=airflow
AIRFLOW_GROUP=airflow
AIRFLOW_VENV_PATH=/home/airflow/airflow/.venv
AIRFLOW_BIN=/home/airflow/airflow/.venv/bin/airflow
AIRFLOW_SYSCONFIG=/etc/sysconfig/airflow

printf "AIRFLOW_HOME=${AIRFLOW_HOME}\n" | sudo tee $AIRFLOW_SYSCONFIG
printf "AIRFLOW_USER=${AIRFLOW_USER}\n" | sudo tee -a $AIRFLOW_SYSCONFIG
printf "AIRFLOW_GROUP=${AIRFLOW_GROUP}\n" | sudo tee -a $AIRFLOW_SYSCONFIG
printf "AIRFLOW_VENV_PATH=${AIRFLOW_VENV_PATH}\n" | sudo tee -a $AIRFLOW_SYSCONFIG
printf "AIRFLOW_BIN=${AIRFLOW_BIN}\n" | sudo tee -a $AIRFLOW_SYSCONFIG

# Create airflow-api-server.service file
sudo tee /etc/systemd/system/airflow-api-server.service << EOF
[Unit]
Description=Airflow API server daemon
After=network.target postgresql.service mysql.service redis.service rabbitmq-server.service
Wants=postgresql.service mysql.service redis.service rabbitmq-server.service

[Service]
EnvironmentFile=${AIRFLOW_SYSCONFIG}
User=${AIRFLOW_USER}
Group=${AIRFLOW_GROUP}
Type=simple
ExecStart=/bin/bash -c 'source ${AIRFLOW_VENV_PATH}/bin/activate && airflow api-server --pid /run/airflow/api-server.pid'
Restart=on-failure
RestartSec=5s
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF

# Create airflow-scheduler.service file
sudo tee /etc/systemd/system/airflow-scheduler.service << EOF
[Unit]
Description=Airflow scheduler daemon
After=network.target postgresql.service mysql.service redis.service rabbitmq-server.service
Wants=postgresql.service mysql.service redis.service rabbitmq-server.service

[Service]
EnvironmentFile=${AIRFLOW_SYSCONFIG}
User=${AIRFLOW_USER}
Group=${AIRFLOW_GROUP}
Type=simple
ExecStart=/bin/bash -c 'source ${AIRFLOW_VENV_PATH}/bin/activate && airflow scheduler'
Restart=always
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF

# Create airflow-dag-processor.service file
sudo tee /etc/systemd/system/airflow-dag-processor.service << EOF
[Unit]
Description=Airflow DAG processor daemon
After=network.target postgresql.service mysql.service redis.service rabbitmq-server.service
Wants=postgresql.service mysql.service redis.service rabbitmq-server.service

[Service]
EnvironmentFile=${AIRFLOW_SYSCONFIG}
User=${AIRFLOW_USER}
Group=${AIRFLOW_GROUP}
Type=simple
ExecStart=/bin/bash -c 'source ${AIRFLOW_VENV_PATH}/bin/activate && airflow dag-processor'
Restart=always
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF

# Create airflow-triggerer.service file
sudo tee /etc/systemd/system/airflow-triggerer.service << EOF
[Unit]
Description=Airflow triggerer daemon
After=network.target postgresql.service mysql.service redis.service rabbitmq-server.service
Wants=postgresql.service mysql.service redis.service rabbitmq-server.service

[Service]
EnvironmentFile=${AIRFLOW_SYSCONFIG}
User=${AIRFLOW_USER}
Group=${AIRFLOW_GROUP}
Type=simple
ExecStart=/bin/bash -c 'source ${AIRFLOW_VENV_PATH}/bin/activate && airflow triggerer'
Restart=always
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF

# Reload/enable services
sudo systemctl daemon-reload
sudo systemctl enable airflow-api-server.service
sudo systemctl enable airflow-scheduler.service
sudo systemctl enable airflow-dag-processor.service
sudo systemctl enable airflow-triggerer.service

source $AIRFLOW_VENV_PATH/bin/activate
export AIRFLOW_HOME=$AIRFLOW_HOME
airflow config list --defaults
cp $AIRFLOW_HOME/airflow.cfg $AIRFLOW_HOME/airflow.cfg.bak
sed -i "s/^sql_alchemy_conn = .*/sql_alchemy_conn = postgresql+psycopg2:\/\/airflow_user:123@127.0.0.1\/airflow_db/" $AIRFLOW_HOME/airflow.cfg
sed -i "s/^auth_manager = .*/auth_manager = airflow.providers.fab.auth_manager.fab_auth_manager.FabAuthManager/" $AIRFLOW_HOME/airflow.cfg
sed -i "s/^load_examples = .*/load_examples = False/" $AIRFLOW_HOME/airflow.cfg
airflow db migrate
airflow users create --username $ADMIN_USER --firstname $ADMIN_FIRSTNAME --lastname $ADMIN_LASTNAME --role Admin --email $ADMIN_EMAIL
