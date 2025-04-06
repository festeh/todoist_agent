import io
import contextlib
from src.todoist_manager import TodoistManager


class CodeManager:
    def __init__(self):
        manager = TodoistManager(use_async=False)
        self._client = manager._todoist_sync

    def execute(self, code: str) -> tuple[bool, str]:
        """
        Executes the provided Python code string and captures its stdout.

        Args:
            code: A string containing the Python code to execute.

        Returns:
            A tuple containing:
                - bool: True if execution was successful, False otherwise.
                - str: The captured standard output from the executed code.
        """
        stdout_capture = io.StringIO()
        try:
            execution_globals = {"client": self._client}
            execution_locals: dict = dict()

            with contextlib.redirect_stdout(stdout_capture):
                exec(code, execution_globals, execution_locals)

            captured_output = stdout_capture.getvalue()
            print(f"Successfully executed code:\n{code}\nOutput:\n{captured_output}")
            return True, captured_output

        except Exception as e:
            captured_output = stdout_capture.getvalue() # Capture output even on error
            print(f"Error executing code:\n{code}\nError: {e}\nOutput:\n{captured_output}")
            return False, captured_output
