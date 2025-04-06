from src.code_manager import CodeManager


def test_list_empty_projects():
    manager = CodeManager()
    code = """projects = client.get_projects()[:3]
empty_projects = [project.name for project in projects if not client.get_tasks(project_id=project.id)]
empty_projects
    """.strip()
    result = manager.execute(code)
    assert result[0]


def test_count_tasks_for_today():
    code = """from datetime import datetime

def count_tasks_for_today(client):
    tasks = client.get_tasks()
    today = datetime.now().strftime('%Y-%m-%d')
    count = sum(1 for task in tasks if task.due and task.due.date == today)
    return count

print(count_tasks_for_today(client))"""
    manager = CodeManager()
    result = manager.execute(code)
    assert result[0]
