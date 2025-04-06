import io
import contextlib
import datetime
from src.todoist_manager import TodoistManager


class CodeManager:
    def __init__(self):
        manager = TodoistManager(use_async=False)
        self._client = manager._todoist_sync

    def execute(self, code: str) -> tuple[bool, str]:
        stdout_capture = io.StringIO()
        try:
            # Provide the 'client' object and necessary modules like 'datetime'.
            execution_globals = {"client": self._client, "datetime": datetime}
            # Locals start empty, but can be the same dict as globals if desired
            execution_locals: dict[str, object] = {}

            with contextlib.redirect_stdout(stdout_capture):
                exec(code, execution_globals, execution_locals)

            captured_output = stdout_capture.getvalue().strip()

            vars: list[str] = [""]
            # del execution_locals["client"]
            for key, value in execution_locals.items():
                vars.append(f"{key}: {value}")
            captured_output += "\n".join(vars)

            print(
                f"Successfully executed code:\n{code}\nOutput:\n{captured_output.strip()}"
            )
            return True, captured_output.strip()

        except Exception as e:
            captured_output = stdout_capture.getvalue()  # Capture output even on error
            print(
                f"Error executing code:\n{code}\nError: {e}\nOutput:\n{captured_output}"
            )
            return False, captured_output
