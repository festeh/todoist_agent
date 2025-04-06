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


def test_ai_manager_response():
    todoist_manager = TodoistManager()
    ai_manager = AiManager()
    tasks = asyncio.run(todoist_manager.get_tasks())
    code_info = todoist_manager.get_code_info()
    user_request = "Добавь задачу на завтра - почитать книгу"
    response = ai_manager.get_code_ai_response(tasks, code_info, user_request)
    print(response)


def test_ai_manager_summary():
    ai_manager = AiManager()
    request = "Поставь задачу на завтра - 50 страниц гтд"
    code = """task_content = "50 страниц гтд"
due_date = "tomorrow"
project_name = "Книги по продуктивности"

projects = client.get_projects()
project_id = next((p.id for p in projects if p.name == project_name), None)
if project_id is None:
    project = client.add_project(project_name)
    project_id = project.id

 client.add_task(content=task_content, project_id=project_id, due_string=due_date)
    """.strip()
    result = """
Successfully executed code:
    """.strip()
    summary = ai_manager.get_answer_ai_response(request, code, result)
    print(summary)
