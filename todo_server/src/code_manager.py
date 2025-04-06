import io
import contextlib
from src.todoist_manager import TodoistManager


class CodeManager:
    def __init__(self):
        manager = TodoistManager(use_async=False)
        self._client = manager._todoist_sync

    def execute(self, code: str) -> tuple[bool, str]:
        stdout_capture = io.StringIO()
        try:
            # Make the 'client' object and 'datetime' module available to the executed code
            execution_globals = {
                "client": self._client,
                "datetime": datetime
            }
            # Locals start empty, but can be the same dict as globals if desired
            execution_locals: dict[str, object] = {}

            with contextlib.redirect_stdout(stdout_capture):
                exec(code, execution_globals, execution_locals)

            captured_output = stdout_capture.getvalue().strip()

            # If no stdout, capture the last assigned variable's value
            if not captured_output and execution_locals:
                 # Get the name of the last assigned variable
                last_var_name = list(execution_locals.keys())[-1]
                last_var_value = execution_locals[last_var_name]
                captured_output = repr(last_var_value)
                print(f"No stdout captured. Using value of last variable: {last_var_name}")
            elif not captured_output:
                 captured_output = "Code executed successfully, but produced no output or variables."
                 print(captured_output)

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
