from typing import List
from todoist_api_python.api_async import TodoistAPIAsync
from dotenv import load_dotenv
import os

from todoist_api_python.models import Task

_ = load_dotenv()

class TodoistManager:
    def __init__(self):
        todoist_api_token = os.getenv("TODOIST_API_KEY")
        if not todoist_api_token:
            raise ValueError("TODOIST_API_KEY environment variable not set.")
        self._todoist: TodoistAPIAsync = TodoistAPIAsync(todoist_api_token)

    async def get_tasks(self) -> str:
        tasks: list[Task] = await self._todoist.get_tasks()
        projects = await self._todoist.get_projects()
        return tasks
