#!/bin/bash
set -e

git clone --single-branch -b $branch https://$GITHUB_TOKEN@github.com/nahplay/snowflake_dbt.git

mv snowflake_dbt app

cd app

pip3 install -r requirements.txt

chmod +x $DBT_JOB_PATH

./$DBT_JOB_PATH
