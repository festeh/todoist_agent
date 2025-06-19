from typing import Any, final
from todoist_api_python.api import TodoistAPI
from todoist_api_python.api_async import TodoistAPIAsync

from todoist_api_python.models import ApiDue, Task, Project


from dotenv import load_dotenv
import os
import asyncio
from datetime import date, datetime
import httpx
import json
from loguru import logger
import operator
from dataclass_wizard import JSONPyWizard
from dataclasses import dataclass

_ = load_dotenv()


def format_context(projects: list[Project], tasks: list[Task]) -> str:
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


@dataclass
class FilterProjectId:
    id: str


@dataclass
class FilterProjectName:
    name: str


@dataclass
class FilterTaskNameMatches:
    substring: str


@dataclass
class FilterTaskDue:
    before: date | datetime | None = None
    on: date | datetime | None = None
    after: date | datetime | None = None


@dataclass
class FilterAND:
    filters: list["Filter"]


@dataclass
class FilterOR:
    filters: list["Filter"]


type Filter = (
    FilterProjectId
    | FilterProjectName
    | FilterTaskNameMatches
    | FilterTaskDue
    | FilterAND
    | FilterOR
)


@dataclass
class SyncEndpointResponse(JSONPyWizard):
    class _(JSONPyWizard.Meta):  # noqa:N801
        v1 = True

    projects: list[Project]
    items: list[Task]
    sync_token: str


@final
class TodoistManagerSyncEndpoint:
    def __init__(self):
        todoist_api_token = os.getenv("TODOIST_API_KEY")
        if not todoist_api_token:
            logger.error("TODOIST_API_KEY environment variable not set.")
            raise ValueError("TODOIST_API_KEY environment variable not set.")
        self._api_token = todoist_api_token
        self._projects: list[Project] = []
        self._items: list[Task] = []
        self._load_cache()
        self._sync_url = "https://api.todoist.com/sync/v9/sync"

    def _get_sync_token_path(self) -> str:
        xdg_data_home = os.getenv("XDG_DATA_HOME", os.path.expanduser("~/.local/share"))
        app_data_dir = os.path.join(xdg_data_home, "todo_server")
        os.makedirs(app_data_dir, exist_ok=True)
        return os.path.join(app_data_dir, "sync_token")

    def _get_data_cache_path(self) -> str:
        xdg_data_home = os.getenv("XDG_DATA_HOME", os.path.expanduser("~/.local/share"))
        app_data_dir = os.path.join(xdg_data_home, "todo_server")
        os.makedirs(app_data_dir, exist_ok=True)
        return os.path.join(app_data_dir, "sync_data.json")

    def _load_cache(self):
        self._sync_token_file = self._get_sync_token_path()
        try:
            with open(self._sync_token_file, "r") as f:
                token = f.read().strip()
                self._sync_token = token if token else "*"
        except FileNotFoundError:
            self._sync_token = "*"  # Start with full sync

        self._data_cache_file = self._get_data_cache_path()
        try:
            with open(self._data_cache_file, "r") as f:
                data = json.load(f)
                self._projects = [Project.from_dict(p) for p in data.get("projects", [])]
                self._items = [Task.from_dict(t) for t in data.get("items", [])]
        except (FileNotFoundError, json.JSONDecodeError):
            self._projects = []
            self._items = []
            self._sync_token = "*"  # if data is gone, we need a full sync

    def _save_cache(self):
        with open(self._sync_token_file, "w") as f:
            _ = f.write(self._sync_token)

        self._data_cache_file = self._get_data_cache_path()
        with open(self._data_cache_file, "w") as f:
            data = {
                "projects": [p.to_dict() for p in self._projects],
                "items": [t.to_dict() for t in self._items],
            }
            json.dump(data, f)

    async def get_context(self) -> str:
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

        _ =response.raise_for_status()

        result: dict[str, Any] = response.json()

        if "sync_token" in result:
            self._sync_token: str = result["sync_token"]

        new_projects = [Project.from_dict(p) for p in result.get("projects", [])]
        new_items = [Task.from_dict(t) for t in result.get("items", [])]

        if result.get("full_sync"):
            self._projects = new_projects
            self._items = new_items
        else:
            # Update projects
            project_map = {p.id: p for p in self._projects}
            for p in new_projects:
                project_map[p.id] = p
            self._projects = list(project_map.values())

            # Update items
            item_map = {i.id: i for i in self._items}
            for i in new_items:
                item_map[i.id] = i
            self._items = list(item_map.values())

        self._save_cache()

        return format_context(self._projects, self._items)

    def get_tasks(self, filter_obj: Filter | None = None) -> list[Task]:
        if not filter_obj:
            return self._items

        return [
            task for task in self._items if self._task_matches_filter(task, filter_obj)
        ]

    def _task_matches_filter(self, task: Task, filter_obj: Filter) -> bool:
        if isinstance(filter_obj, FilterProjectId):
            return task.project_id == filter_obj.id

        if isinstance(filter_obj, FilterProjectName):
            project_map = {p.name: p.id for p in self._projects}
            project_id = project_map.get(filter_obj.name)
            return project_id is not None and task.project_id == project_id

        if isinstance(filter_obj, FilterTaskNameMatches):
            return filter_obj.substring.lower() in task.content.lower()

        if isinstance(filter_obj, FilterTaskDue):
            if not any([filter_obj.on, filter_obj.before, filter_obj.after]):
                return False
            if not task.due:
                return False

            task_due_obj = task.due.date 
            def _compare(val1: ApiDue, val2, op) -> bool:
                if type(val1) is not type(val2):
                    v1 = val1.date() if isinstance(val1, datetime) else val1
                    v2 = val2.date() if isinstance(val2, datetime) else val2
                    return op(v1, v2)
                return op(val1, val2)

            if filter_obj.on:
                if not _compare(task_due_obj, filter_obj.on, operator.eq):
                    return False
            if filter_obj.before:
                if not _compare(task_due_obj, filter_obj.before, operator.lt):
                    return False
            if filter_obj.after:
                if not _compare(task_due_obj, filter_obj.after, operator.gt):
                    return False
            return True

        if isinstance(filter_obj, FilterAND):
            return all(
                self._task_matches_filter(task, f) for f in filter_obj.filters
            )

        # FilterOR
        return any(
            self._task_matches_filter(task, f) for f in filter_obj.filters
        )


    def get_projects(self) -> list[Project]:
        return self._projects

    def get_project(self, id: str) -> Project:
        p = next((p for p in self._projects if p.id == id), None)
        if not p:
            raise ValueError(f"Project with id {id} not found")
        return p


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

        return format_context(projects, tasks)
