from google.cloud.devtools.cloudbuild import CloudBuildClient


class CloudBuildEvent:
    def __init__(self, payload):
        self._client = CloudBuildClient()
        self.build_trigger = self._get_trigger(
            payload.get("projectId"), payload.get("buildTriggerId")
        )
        self.substitutions = payload.get("substitutions", {})

        self.id = payload.get("id")
        self.project_id = payload.get("projectId")
        self.status = payload.get("status")
        self.log_url = payload.get("logUrl")
        self.trigger_name = self.substitutions.get("TRIGGER_NAME")
        self.repo_branch = self.substitutions.get("BRANCH_NAME")
        self.commit_sha = self.substitutions.get("COMMIT_SHA")
        self.short_sha = self.substitutions.get("SHORT_SHA")
        self.pr_number = self.substitutions.get("_PR_NUMBER")

    def _get_trigger(self, project_id, trigger_id):
        trigger = self._client.get_build_trigger(
            project_id=project_id, trigger_id=trigger_id
        )
        return trigger

    @property
    def github_repo(self):
        if self.build_trigger.github is not None:
            return f"{self.build_trigger.github.owner}/{self.build_trigger.github.name}"
        return None

    @property
    def github_repo_url(self):
        if self.github_repo is not None:
            return f"https://github.com/{self.github_repo}"
        return None

    @property
    def github_commit_url(self):
        if self.github_repo_url is not None:
            return f"{self.github_repo_url}/commit/{self.commit_sha}"
        return None

    @property
    def github_pr_url(self):
        if self.github_repo_url is not None and self.pr_number is not None:
            return f"{self.github_repo_url}/pull/{self.pr_number}"
        return None

    @property
    def github_branch_url(self):
        if self.github_repo_url is not None:
            return f"{self.github_repo_url}/tree/{self.repo_branch}"
        return None
