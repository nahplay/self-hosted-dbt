import json
import requests
import os
from datetime import datetime


def extract_event_data(event):
    sns_message = json.loads(event['Records'][0]['Sns']['Message'])
    containers = sns_message['detail']['containers'][0]
    return sns_message, containers


def format_image_info(image):
    if 'amazonaws.com' in image:
        account, rest = image.split('.', 1)
        repo, tag = rest.split('/')[1].split(':')
        return (
            f"*{account}* account was used for a job\n"
            f"repository: *{repo}*\n"
            f"tag: *{tag}*"
        )
    else:
        return '*No image info available for the image*'


# Determine job timings
def calculate_job_timing(started_at, finished_at):
    datetime1 = datetime.strptime(started_at, "%Y-%m-%dT%H:%M:%S.%fZ")
    datetime2 = datetime.strptime(finished_at, "%Y-%m-%dT%H:%M:%S.%fZ")
    time_difference = datetime2 - datetime1
    seconds = time_difference.total_seconds() % 60
    hours = int(seconds // 3600)
    minutes = int((seconds % 3600) // 60)
    return f"{hours} hours, {minutes} minutes, {seconds:.1f} seconds"


# Generate CloudWatch link for ECS
def generate_cloudwatch_link(event, image):
    try:
        task_arn = json.loads(event['Records'][0]['Sns']['Message'])['detail']['containers'][0]['taskArn'].split('/')[
            -1]
        availability_zone = os.environ['AVAILABILITY_ZONE']
        job_name = json.loads(event['Records'][0]['Sns']['Message'])['detail']['group'].split(':')[1]
        cloudwatch_link = f"https://{availability_zone}.console.aws.amazon.com/cloudwatch/home?region={availability_zone}#logsV2:log-groups/log-group/$252Fecs$252F{job_name}/log-events/ecs$252F{image.split('.', 1)[1].split('/')[1].split(':')[0]}$252F{task_arn}"
    except IndexError:
        cloudwatch_link = '*Link is not available.*'
    return cloudwatch_link


def lambda_handler(event, context):
    sns_message, containers = extract_event_data(event)

    job_status = 'was successful! :white_check_mark:' if containers[
                                                             'exitCode'] == 0 else 'has failed! Please take a :eyes: :red_circle: :x: <!channel>'
    image_info = format_image_info(containers['image'])
    job_timing = calculate_job_timing(sns_message['detail']['startedAt'], sns_message['detail']['stoppedAt'])
    cloudwatch_link = generate_cloudwatch_link(event, containers['image'])

    dataset = {
        'text': (
            f'The *{sns_message["detail"]["group"].split(":")[1]} {job_status}* :robot_face:\n\n'
            f'Started at: *{sns_message["detail"]["startedAt"]} UTC*\n'
            f'Finished at: *{sns_message["detail"]["stoppedAt"]} UTC*\n'
            f'Job took ~ *{job_timing}* :stopwatch:\n\n'
            'Image info: :rocket:\n'
            f'{image_info}\n'
            f'CloudWatch link :globe_with_meridians: : {cloudwatch_link}'
        )
    }

    headers = {
        'Content-type': 'application/json'
    }

    requests.post(os.environ['DBT_SLACK_WEBHOOK_URL'], data=json.dumps(dataset).encode("utf-8"),
                  headers=headers)

    return None
