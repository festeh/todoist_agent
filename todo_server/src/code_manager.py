import io
import contextlib
import datetime
from loguru import logger
from src.todoist_manager import TodoistManager


class CodeManager:
    def __init__(self):
        manager = TodoistManager(use_async=False)
        self._client = manager._todoist_sync

    def execute(self, code: str) -> str:
        stdout_capture = io.StringIO()
        try:
            execution_scope = {"client": self._client}

            with contextlib.redirect_stdout(stdout_capture):
                exec(code, execution_scope, execution_scope)
            captured_output = stdout_capture.getvalue().strip()
            result_message = f"Successfully executed code:\n {captured_output}".strip()
            logger.info(result_message)
            return result_message

        except Exception as e:
            captured_output = stdout_capture.getvalue().strip()
            error_message = f"Error executing code: {e}\nstdout: {captured_output}"
            logger.error(error_message)
            return error_message
