from dataclasses import dataclass
from datetime import date, datetime
from typing import final
from dotenv import load_dotenv
import os
from loguru import logger
import inspect

from todoist_api_python.models import Task as TodoistTask
from todoist_api_python.api import TodoistAPI

_ = load_dotenv()


@dataclass
class Project:
    id: str
    name: str
    is_favorite: bool


@dataclass
class Task:
    id: str
    content: str
    project_id: str
    priority: int
    due: date | datetime | None
    # due_datetime: datetime | None


@dataclass
class UnaryFilter:
    project_id: str | None
    project_name: str | None
    task_name: str | None


type Filter = UnaryFilter


@final
class TaskClient:
    def __init__(self):
        token = os.getenv("TODOIST_API_KEY")
        if not token:
            raise ValueError("TODOIST_API_KEY environment variable not set.")
        self.todoist = TodoistAPI(token)

    def get_project_by_id(self, id: str) -> Project:
        project = self.todoist.get_project(id)
        return Project(
            id=project.id, name=project.name, is_favorite=project.is_favorite
        )

    def get_all_projects(self) -> list[Project]:
        projects = self.todoist.get_projects()
        return [
            Project(id=project.id, name=project.name, is_favorite=project.is_favorite)
            for project_page in projects
            for project in project_page
        ]

    def add_project(self, name: str, is_favorite: bool = False) -> Project:
        project = self.todoist.add_project(name, is_favorite=is_favorite)
        return Project(
            id=project.id, name=project.name, is_favorite=project.is_favorite
        )

    def remove_project(self, id: str) -> bool:
        return self.todoist.delete_project(id)

    def _convert_to_local_task(self, task: TodoistTask) -> Task:
        """Converts a Todoist API Task object to the local Task dataclass."""
        return Task(
            id=task.id,
            content=task.content,
            project_id=task.project_id,
            priority=task.priority,
            due=task.due.date if task.due else None,
            # due_date=task.due.date if task.due and isinstance(task.due.date, date) and not isinstance(task.due.date, datetime) else None,
            # due_datetime=task.due.date if task.due and isinstance(task.due.date, datetime) else None,
        )

    def get_tasks(self, project_id: str | None = None) -> list[Task]:
        tasks = self.todoist.get_tasks(project_id=project_id)
        return [
            self._convert_to_local_task(task)
            for task_page in tasks
            for task in task_page
        ]

    def add_task(
        self,
        content: str,
        project_id: str | None = None,
        due_date: date | None = None,
        due_datetime: datetime | None = None,
        priority: int | None = None,
    ) -> Task:
        task = self.todoist.add_task(
            content,
            project_id=project_id,
            due_date=due_date,
            due_datetime=due_datetime,
            priority=priority,
        )
        return self._convert_to_local_task(task)

    def complete_task(self, task_id: str) -> bool:
        return self.todoist.complete_task(task_id)

    def _get_class_fields_info(self, cls: type) -> list[str]:
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
            "get_code_info",
            "__get_class_fields_info",
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
