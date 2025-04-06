from src.todoist_manager import TodoistManager


class CodeManager:
    def __init__(self):
        pass

    def execute(self, code: str):
        client = TodoistManager(use_async=False)._todoist_sync
