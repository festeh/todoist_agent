from dataclasses import dataclass
from datetime import date, datetime
from typing import final
from dotenv import load_dotenv
import os

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
    due_date: date | None
    due_datetime: datetime | None


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

    def get_tasks(self, project_id: str | None = None) -> list[Task]:
        tasks = self.todoist.get_tasks(project_id=project_id)
        return [
            Task(
                id=task.id,
                content=task.content,
                project_id=task.project_id,
                priority=task.priority,
                due=None if task.due is None else task.due.date,
            )
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
        return Task(
            id=task.id,
            content=task.content,
            project_id=task.project_id,
            priority=task.priority,
            due=None if task.due is None else task.due.date,
        )

    def complete_task(self, task_id: str) -> bool:
        return self.todoist.complete_task(task_id)
