from src.code_manager import CodeManager


def test_list_empty_projects():
    manager = CodeManager()
    code = """projects = client.get_projects()[:3]
empty_projects = [project.name for project in projects if not client.get_tasks(project_id=project.id)]
empty_projects
    """.strip()
    result = manager.execute(code)
    assert result[0]
