import io
import contextlib
import datetime
from src.todoist_manager import TodoistManager


class CodeManager:
    def __init__(self):
        manager = TodoistManager(use_async=False)
        self._client = manager._todoist_sync

    def execute(self, code: str) -> str:
        stdout_capture = io.StringIO()
        try:
            execution_scope = {"client": self._client, "datetime": datetime}

            with contextlib.redirect_stdout(stdout_capture):
                exec(code, execution_scope, execution_scope)

            captured_output = stdout_capture.getvalue().strip()

            vars_list: list[str] = [""]
            filtered_locals = {
                k: v
                for k, v in execution_scope.items()
                if k not in ["client", "datetime", "__builtins__"]
            }
            for key, value in filtered_locals.items():
                vars_list.append(f"{key}: {value}")
            captured_output += "\n".join(vars_list)

            captured_output = f"Successfully executed code:\n {captured_output}".strip()
            print(captured_output)
            return captured_output

        except Exception as e:
            captured_output = stdout_capture.getvalue()
            result = f"Error executing code:\n {e}. Output: {captured_output}"
            print(result)
            return captured_output
