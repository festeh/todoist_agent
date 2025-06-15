from typing import final
from todoist_api_python.api import TodoistAPI
from todoist_api_python.api_async import TodoistAPIAsync
from dotenv import load_dotenv
import os
import asyncio
from datetime import date, datetime
import inspect
import requests
import json
import uuid
from loguru import logger

from src.task_client import TaskClient, Task, Project

_ = load_dotenv()

@final
class TodoistManagerSyncEndpoint:
    def __init__(self):
        todoist_api_token = os.getenv("TODOIST_API_KEY")
        if not todoist_api_token:
            logger.error("TODOIST_API_KEY environment variable not set.")
            raise ValueError("TODOIST_API_KEY environment variable not set.")
        self._api_token = todoist_api_token

        xdg_data_home = os.getenv("XDG_DATA_HOME", os.path.expanduser("~/.local/share"))
        app_data_dir = os.path.join(xdg_data_home, "todo_server")
        os.makedirs(app_data_dir, exist_ok=True)
        self._sync_token_file = os.path.join(app_data_dir, "sync_token")

        try:
            with open(self._sync_token_file, "r") as f:
                token = f.read().strip()
                self._sync_token = token if token else "*"
        except FileNotFoundError:
            self._sync_token = "*"  # Start with full sync
        
        self._sync_url = "https://api.todoist.com/sync/v9/sync"

    def _make_sync_request(self, commands: list[dict] = None) -> dict:
        headers = {
            "Authorization": f"Bearer {self._api_token}",
            "Content-Type": "application/x-www-form-urlencoded"
        }
        
        data = {
            "sync_token": self._sync_token,
            "resource_types": json.dumps(["projects", "items"])
        }
        
        if commands:
            data["commands"] = json.dumps(commands)
        
        response = requests.post(self._sync_url, headers=headers, data=data)
        response.raise_for_status()
        
        result = response.json()
        # Update sync token for incremental syncs
        if "sync_token" in result:
            self._sync_token = result["sync_token"]
            with open(self._sync_token_file, "w") as f:
                f.write(self._sync_token)
        
        return result

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

        output_lines = []
        # Sort projects by name for consistent output
        sorted_project_ids = sorted(
            tasks_by_project.keys(), key=lambda pid: project_map.get(pid, "")
        )

        for project_id in sorted_project_ids:
            task_lines = tasks_by_project[project_id]
            project_name = project_map.get(project_id, "Unknown Project")
            output_lines.append(project_name)
            # Tasks are already formatted with due dates
            output_lines.extend(task_lines)

        return "\n".join(output_lines)


    def sync_add_task(self, content: str, project_id: str = None, due_string: str = None, 
                     priority: int = 1, labels: list[str] = None) -> dict:
        """Add a task using the Sync API."""
        command_uuid = str(uuid.uuid4())
        
        args = {
            "content": content,
            "priority": priority
        }
        
        if project_id:
            args["project_id"] = project_id
        if due_string:
            args["due"] = {"string": due_string}
        if labels:
            args["labels"] = labels
        
        commands = [{
            "type": "item_add",
            "uuid": command_uuid,
            "args": args
        }]
        
        return self._make_sync_request(commands=commands)

    def sync_update_task(self, task_id: str, content: str = None, due_string: str = None,
                        priority: int = None, labels: list[str] = None) -> dict:
        """Update a task using the Sync API."""
        command_uuid = str(uuid.uuid4())
        
        args = {"id": task_id}
        
        if content is not None:
            args["content"] = content
        if due_string is not None:
            args["due"] = {"string": due_string}
        if priority is not None:
            args["priority"] = priority
        if labels is not None:
            args["labels"] = labels
        
        commands = [{
            "type": "item_update",
            "uuid": command_uuid,
            "args": args
        }]
        
        return self._make_sync_request(commands=commands)

    def sync_complete_task(self, task_id: str) -> dict:
        """Complete a task using the Sync API."""
        command_uuid = str(uuid.uuid4())
        
        commands = [{
            "type": "item_complete",
            "uuid": command_uuid,
            "args": {"id": task_id}
        }]
        
        return self._make_sync_request(commands=commands)

    def sync_delete_task(self, task_id: str) -> dict:
        """Delete a task using the Sync API."""
        command_uuid = str(uuid.uuid4())
        
        commands = [{
            "type": "item_delete",
            "uuid": command_uuid,
            "args": {"id": task_id}
        }]
        
        return self._make_sync_request(commands=commands)

    def sync_batch_operations(self, operations: list[dict]) -> dict:
        """Perform multiple operations in a single sync request.
        
        Args:
            operations: List of operation dicts with keys:
                - type: Operation type (item_add, item_update, item_complete, item_delete)
                - args: Operation arguments
        """
        commands = []
        for op in operations:
            commands.append({
                "type": op["type"],
                "uuid": str(uuid.uuid4()),
                "args": op["args"]
            })
        
        return self._make_sync_request(commands=commands)

    def sync_get_data(self, resource_types: list[str] = None) -> dict:
        """Get data using incremental sync."""
        return self._make_sync_request(resource_types=resource_types or ["items", "projects"])

    def _get_class_fields_info(self, cls: type) -> list[str]:
        """Inspects a class and returns a list describing its fields and types."""
        result = [f"class {cls.__name__}:"]
        try:
            annotations = inspect.get_annotations(cls)
            for name, type_hint in annotations.items():
                type_name = getattr(type_hint, "__name__", repr(type_hint))
                # Handle Optional types for better readability
                if "Optional[" in repr(type_hint):
                    inner_type_repr = repr(type_hint).split("[", 1)[1].rsplit("]", 1)[0]
                    try:
                        inner_type = eval(inner_type_repr, globals(), locals())
                        inner_type_name = getattr(
                            inner_type, "__name__", inner_type_repr
                        )
                        type_name = f"{inner_type_name} | None"
                    except Exception as eval_err:  # Fallback if eval fails or inner type has no __name__
                        logger.warning(
                            f"Could not eval inner type '{inner_type_repr}' for Optional hint: {eval_err}"
                        )
                        type_name = f"{inner_type_repr} | None"

                result.append(f"    {name}: {type_name}")
        except Exception as e:
            logger.error(f"Could not inspect {cls.__name__} fields: {e}")
        return result

    def get_code_info(self):
        client = TaskClient
        ignore = [
            "__init__",
            "__exit__",
            "__enter__",
        ]
        result = ["class TasksAPI:"]
        for method in dir(client):
            if method in ignore:
                continue
            attribute = getattr(client, method)
            if inspect.isfunction(attribute):
                source = inspect.getsource(attribute)
                lines = source.splitlines()
                last_arrow_line_index = -1
                for i in range(len(lines) - 1, -1, -1):
                    if "->" in lines[i]:
                        last_arrow_line_index = i
                        break
                if last_arrow_line_index != -1:
                    signature_lines = lines[: last_arrow_line_index + 1]
                    signature = "\n".join(signature_lines)
                else:
                    # Fallback: Use the first line, strip trailing colon
                    signature = lines[0].strip().rstrip(":")

                result.append(signature.rstrip(":"))
                result.append("")

        # Add info for relevant model classes
        for model_cls in [Task, Project]:
            result.append("")
            result.extend(self._get_class_fields_info(model_cls))
        logger.info("Collected code context")
        return "\n".join(result)
