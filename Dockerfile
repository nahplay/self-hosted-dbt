FROM python:3.9

COPY dbt_default_script.sh dbt_default_script.sh

ENTRYPOINT [ "bash", "dbt_default_script.sh" ]