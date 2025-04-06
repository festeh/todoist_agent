from src.todoist_manager import TodoistManager


class CodeManager:
    def __init__(self):
        manager = TodoistManager(use_async=False)
        self._client = manager._todoist_sync

    def execute(self, code: str):
        try:
            execution_globals = {"client": self._client}
            execution_locals: dict = dict()

            exec(code, execution_globals, execution_locals)

            print(f"Successfully executed code:\n{code}")
            # Consider returning a status or result if needed
            return True  # Indicate success

        except Exception as e:
            print(f"Error executing code:\n{code}\nError: {e}")
            # Consider returning the exception or a specific error status
            return False  # Indicate failure
