import base64
import os
import json

from google.cloud import secretmanager
from slack_sdk.webhook import WebhookClient
from slack_sdk.models.blocks import blocks, basic_components, block_elements
from slack_sdk.models.attachments import BlockAttachment
from events import CloudBuildEvent

GCLOUD_IMAGE_URL = "https://www.gstatic.com/devrel-devsite/prod/v702c60b70d68da067f4d656556a48e4ab1cf14be10bb79e46f353f3fdfe8505d/cloud/images/favicons/onecloud/apple-icon.png"
STATUS_COLOR = {
    "DEFAULT": "#A3A1A1",
    "QUEUED": "#A3A1A1",
    "WORKING": "#38A5FF",
    "FAILURE": "#FF334C",
    "SUCCESS": "#36A64F",
}


def build_attachments(event):
    """
    Builds Slack "Attachments" to be sent in the body of our notification.

    :param event: A Cloud Build event
    :type event: CloudBuildEvent
    :return: The Slack Attachments
    :rtype: dict of BlockAttachment
    """
    pr_text = (
        f"<{event.github_pr_url}|#{event.pr_number}>" if event.pr_number else "N/A"
    )

    att = BlockAttachment(
        color=STATUS_COLOR.get(event.status, STATUS_COLOR["DEFAULT"]),
        blocks=[
            blocks.HeaderBlock(text=f"Build {event.status.capitalize()}"),
            blocks.SectionBlock(
                text=f"*Build:*\n<{event.log_url}|{event.trigger_name}>"
            ),
            blocks.SectionBlock(
                fields=[
                    basic_components.MarkdownTextObject(
                        text=f"*Pull Request:*\n{pr_text}"
                    ),
                    basic_components.MarkdownTextObject(
                        text=f"*Repo:*\n<{event.github_repo_url}|{event.github_repo}>"
                    ),
                    basic_components.MarkdownTextObject(
                        text=f"*Commit:*\n<{event.github_commit_url}|{event.short_sha}>"
                    ),
                    basic_components.MarkdownTextObject(
                        text=f"*Branch:*\n<{event.github_branch_url}|{event.repo_branch}>"
                    ),
                ]
            ),
            blocks.ContextBlock(
                elements=[
                    block_elements.ImageElement(
                        image_url=GCLOUD_IMAGE_URL, alt_text="GCP Logo"
                    ),
                    basic_components.PlainTextObject(
                        text=f"Project: {event.project_id}"
                    ),
                ]
            ),
        ],
    )

    return [att.to_dict()]


def send_event_notification(slack_client, event):
    """
    Sends a build notification for the provided event to Slack

    :param slack_client: An instance of a Slack webhook client
    :type slack_client: WebhookClient
    :param event: A Cloud Build event
    :type event: CloudBuildEvent
    """

    slack_client.send(attachments=build_attachments(event))


def get_slack_client(slack_webhook_secret_id):
    """
    Pulls the Slack Webhook URL from Google Secret Manager

    :param slack_webhook_secret_id: The secret name in which the URL is stored
    :type slack_webhook_secret_id: str
    :return: An instance of a Slack webhook client
    :rtype: WebhookClient
    """
    client = secretmanager.SecretManagerServiceClient()
    name = f"{slack_webhook_secret_id}/versions/latest"
    response = client.access_secret_version(request={"name": name})
    webhook_url = response.payload.data.decode("UTF-8")

    return WebhookClient(url=webhook_url)


def handle_cloudbuild_event(raw_event, context):
    """
    Background Cloud Function to be triggered by Pub/Sub.

    :param raw_event: The dictionary with data specific to this type of event.
    The `data` field contains the PubsubMessage message. The `attributes`
    field will contain custom attributes if there are any.
    :type raw_event: dict
    :param context: The Cloud Functions event metadata. The `event_id` field
    contains the Pub/Sub message ID. The `timestamp` field contains the publish
    time.
    :type context: google.cloud.functions.Context
    """

    if "data" in raw_event:
        secret_id = os.environ["SECRET_ID"]
        slack_client = get_slack_client(secret_id)

        payload = json.loads(base64.b64decode(raw_event["data"]).decode("utf-8"))
        event = CloudBuildEvent(payload)
        send_event_notification(slack_client, event)
