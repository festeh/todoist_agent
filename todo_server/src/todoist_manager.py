from todoist_api_python.api import TodoistAPI
from todoist_api_python.api_async import TodoistAPIAsync
from dotenv import load_dotenv
import os
import asyncio
from datetime import date, datetime
import inspect

from todoist_api_python.models import Task, Project

_ = load_dotenv()

class TodoistManager:
    def __init__(self):
        todoist_api_token = os.getenv("TODOIST_API_KEY")
        if not todoist_api_token:
            raise ValueError("TODOIST_API_KEY environment variable not set.")
        self._todoist: TodoistAPIAsync = TodoistAPIAsync(todoist_api_token)

    async def get_tasks(self) -> str:
        tasks_coro = self._todoist.get_tasks()
        projects_coro = self._todoist.get_projects()
        results = await asyncio.gather(tasks_coro, projects_coro)

        tasks: list[Task] = results[0]
        projects: list[Project] = results[1]

        project_map: dict[str, str] = {
            project.id: project.name for project in projects
        }

        tasks_by_project: dict[str, list[str]] = {}
        today = date.today()

        for task in tasks:
            project_id = task.project_id
            if project_id not in tasks_by_project:
                tasks_by_project[project_id] = []

            due_str = ""
            if task.due and task.due.date:
                try:
                    due_date = datetime.strptime(task.due.date, "%Y-%m-%d").date()
                    if due_date == today:
                        due_str = " [TODAY]"
                    else:
                        due_str = f" [{due_date.strftime('%d %b %Y')}]"
                except ValueError:
                    print(f"Failed to parse due date: {task.due.date}")
                    due_str = f" [{task.due.string}]" # Fallback to original string

            task_line = f" - {task.content}{due_str}"
            tasks_by_project[project_id].append(task_line)

        output_lines = []
        # Sort projects by name for consistent output
        sorted_project_ids = sorted(tasks_by_project.keys(), key=lambda pid: project_map.get(pid, ""))
        
        for project_id in sorted_project_ids:
            task_lines = tasks_by_project[project_id]
            project_name = project_map.get(project_id, "Unknown Project")
            output_lines.append(project_name)
            # Tasks are already formatted with due dates
            output_lines.extend(task_lines)

        return "\n".join(output_lines)


    def get_code_info(self):
        client = TodoistAPI
        ignore = ["__init__", "__exit__", "__enter__", "get_collaborators"]
        result = ["class TodoistAPI:"]
        for method in dir(client):
            if method in ignore:
                continue
            attribute = getattr(client, method)
            if inspect.isfunction(attribute):
                source = inspect.getsource(attribute)
                signature = source.split('\n')[0].strip(":")
                result.append(signature)
        result.append("")
        result.append("class Task:")
        try:
            # Get annotations for Task fields
            task_annotations = inspect.get_annotations(Task)
            for name, type_hint in task_annotations.items():
                # Format the type hint for better readability
                type_name = getattr(type_hint, '__name__', repr(type_hint))
                # Handle Optional types specifically if needed, e.g., Optional[str] -> str | None
                if "Optional[" in repr(type_hint):
                     inner_type = repr(type_hint).split('[')[1].split(']')[0]
                     # Attempt to get __name__ for inner type if possible
                     try:
                         inner_type_name = eval(inner_type).__name__
                         type_name = f"{inner_type_name} | None"
                     except: # Fallback if eval fails or inner type has no __name__
                         type_name = f"{inner_type} | None"

                result.append(f"    {name}: {type_name}")
        except Exception as e:
            print(f"Could not inspect Task fields: {e}") # Add some error logging

        return "\n".join(result)
