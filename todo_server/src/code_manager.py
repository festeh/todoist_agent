import io
import contextlib
from loguru import logger

from src.task_client import TaskClient


class CodeManager:
    def __init__(self):
        pass

    def execute(self, client: TaskClient, code: str) -> str:
        stdout_capture = io.StringIO()
        try:
            execution_scope = {"client": client}

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
