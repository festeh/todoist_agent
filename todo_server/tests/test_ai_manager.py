from src.ai_manager import AiManager
from src.todoist_manager import TodoistManager
import asyncio

def test_ai_manager_prompt():
    todoist_manager = TodoistManager()
    ai_manager = AiManager()
    tasks = asyncio.run(todoist_manager.get_tasks())
    code_info = todoist_manager.get_code_info()
    prompt = ai_manager.get_system_prompt(tasks, code_info)
    print(prompt)
    assert isinstance(prompt, str)
