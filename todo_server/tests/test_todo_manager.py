from src.todoist_manager import TodoistManager
import asyncio


def test_tasks():
    todoist_manager = TodoistManager()
    tasks = asyncio.run(todoist_manager.get_tasks())
    print(tasks)
    assert isinstance(tasks, str)
