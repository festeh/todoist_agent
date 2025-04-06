from typing import List, Dict
from todoist_api_python.api_async import TodoistAPIAsync
from dotenv import load_dotenv
import os
import asyncio

from todoist_api_python.models import Task, Project

_ = load_dotenv()

class TodoistManager:
    def __init__(self):
        todoist_api_token = os.getenv("TODOIST_API_KEY")
        if not todoist_api_token:
            raise ValueError("TODOIST_API_KEY environment variable not set.")
        self._todoist: TodoistAPIAsync = TodoistAPIAsync(todoist_api_token)

    async def get_tasks(self) -> str:
        # Run fetching tasks and projects concurrently
        tasks_coro = self._todoist.get_tasks()
        projects_coro = self._todoist.get_projects()
        results = await asyncio.gather(tasks_coro, projects_coro)

        tasks: List[Task] = results[0]
        projects: List[Project] = results[1]

        # Create a dictionary for quick project lookup by ID
        project_map: Dict[str, str] = {
            project.id: project.name for project in projects
        }

        # Group tasks by project ID
        tasks_by_project: Dict[str, List[str]] = {}
        for task in tasks:
            project_id = task.project_id
            if project_id not in tasks_by_project:
                tasks_by_project[project_id] = []
            tasks_by_project[project_id].append(task.content)

        # Format the output string
        output_lines = []
        for project_id, task_contents in tasks_by_project.items():
            project_name = project_map.get(project_id, "Unknown Project")
            output_lines.append(project_name)
            for content in task_contents:
                output_lines.append(f" - {content}")

        return "\n".join(output_lines)
