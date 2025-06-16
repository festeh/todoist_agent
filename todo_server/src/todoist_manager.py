from typing import Any, final
from todoist_api_python.api import TodoistAPI
from todoist_api_python.api_async import TodoistAPIAsync

from todoist_api_python.models import Task, Project


from dotenv import load_dotenv
import os
import asyncio
from datetime import date
import httpx
import json
from loguru import logger
from dataclass_wizard import JSONPyWizard
from dataclasses import dataclass

_ = load_dotenv()


@dataclass
class SyncEndpointResponse(JSONPyWizard):
    sync_token: str
    projects: list[Project]
    items: list[Task]


@final
class TodoistManagerSyncEndpoint:
    def __init__(self):
        todoist_api_token = os.getenv("TODOIST_API_KEY")
        if not todoist_api_token:
            logger.error("TODOIST_API_KEY environment variable not set.")
            raise ValueError("TODOIST_API_KEY environment variable not set.")
        self._api_token = todoist_api_token
        self._load_sync_token()
        self._sync_url = "https://api.todoist.com/sync/v9/sync"

    def _get_sync_token_path(self) -> str:
        xdg_data_home = os.getenv("XDG_DATA_HOME", os.path.expanduser("~/.local/share"))
        app_data_dir = os.path.join(xdg_data_home, "todo_server")
        os.makedirs(app_data_dir, exist_ok=True)
        return os.path.join(app_data_dir, "sync_token")

    def _load_sync_token(self):
        self._sync_token_file = self._get_sync_token_path()
        try:
            with open(self._sync_token_file, "r") as f:
                token = f.read().strip()
                self._sync_token = token if token else "*"
        except FileNotFoundError:
            self._sync_token: str = "*"  # Start with full sync

    def _save_sync_token(self):
        with open(self._sync_token_file, "w") as f:
            _ = f.write(self._sync_token)

    async def get_data(self) -> SyncEndpointResponse:
        headers = {
            "Authorization": f"Bearer {self._api_token}",
            "Content-Type": "application/x-www-form-urlencoded",
        }

        data = {
            "sync_token": self._sync_token,
            "resource_types": json.dumps(["projects", "items"]),
        }

        async with httpx.AsyncClient() as client:
            response = await client.post(self._sync_url, headers=headers, data=data)

        response.raise_for_status()

        result: dict[str, Any] = response.json()

        if "sync_token" in result:
            self._sync_token = result["sync_token"]
            self._save_sync_token()

        result.setdefault("projects", [])
        result.setdefault("items", [])

        return SyncEndpointResponse.from_dict(result)


@final
class TodoistManager:
    def __init__(self, use_async: bool = True):
        todoist_api_token = os.getenv("TODOIST_API_KEY")
        if not todoist_api_token:
            logger.error("TODOIST_API_KEY environment variable not set.")
            raise ValueError("TODOIST_API_KEY environment variable not set.")
        self._todoist: TodoistAPIAsync = TodoistAPIAsync(todoist_api_token)
        self._todoist_sync: TodoistAPI = TodoistAPI(todoist_api_token)
        self._api_token = todoist_api_token

    async def get_tasks(self) -> str:
        tasks_coro = self._todoist.get_tasks()
        projects_coro = self._todoist.get_projects()
        tasks, projects_generator = await asyncio.gather(tasks_coro, projects_coro)
        projects = [
            project
            async for project_page in projects_generator
            for project in project_page
        ]
        tasks = [task async for task_page in tasks for task in task_page]

        project_map: dict[str, str] = {project.id: project.name for project in projects}

        tasks_by_project: dict[str, list[str]] = {}
        today = date.today()

        for task in tasks:
            project_id = task.project_id
            if project_id not in tasks_by_project:
                tasks_by_project[project_id] = []

            due_str = ""
            if task.due:
                due = task.due.date
                try:
                    if due == today:
                        due_str = " [today]"
                    else:
                        due_str = f" [{due.strftime('%d %b %Y')}]"
                except ValueError:
                    logger.warning(
                        f"Failed to parse due date '{date}' for task '{task.content}'. Using original string."
                    )
                    due_str = f" [{task.due.string}]"  # Fallback to original string

            task_line = f" - {task.content}{due_str}"
            tasks_by_project[project_id].append(task_line)

        output_lines: list[str] = []
        # Sort projects by name for consistent output
        sorted_project_ids = sorted(
            tasks_by_project.keys(), key=lambda pid: project_map.get(pid, "")
        )

        for project_id in sorted_project_ids:
            task_lines = tasks_by_project[project_id]
            project_name: str = project_map.get(project_id, "Unknown Project")
            output_lines.append(project_name)
            # Tasks are already formatted with due dates
            output_lines.extend(task_lines)

        return "\n".join(output_lines)
