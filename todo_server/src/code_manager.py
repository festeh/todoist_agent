from src.todoist_manager import TodoistManager
# Import the specific client type for clarity if needed, though not strictly required for exec
# from todoist_api_python.api import TodoistAPI


class CodeManager:
    def __init__(self):
        # No initialization needed for now
        pass

    def execute(self, code: str):
        """
        Executes the provided Python code string.

        The code is expected to interact with the Todoist API via a pre-defined
        'client' object, which is made available during execution.

        Args:
            code: A string containing the Python code to execute.
        """
        try:
            # Instantiate the synchronous manager to get the sync client
            # Note: Consider if TodoistManager should be instantiated once per CodeManager instance
            # if CodeManager is long-lived, to avoid repeated authentication/setup.
            # For a single execution, this is fine.
            manager = TodoistManager(use_async=False)
            client = manager._todoist_sync # Access the synchronous client

            # Prepare the global namespace for the exec function
            # This makes the 'client' object available to the executed code
            execution_globals = {"client": client}

            # Execute the code
            # Pass both globals and locals as the same dict for simplicity,
            # ensuring the code runs in a controlled environment.
            exec(code, execution_globals, execution_globals)

            print(f"Successfully executed code:\n{code}")
            # Consider returning a status or result if needed
            return True # Indicate success

        except Exception as e:
            print(f"Error executing code:\n{code}\nError: {e}")
            # Consider returning the exception or a specific error status
            return False # Indicate failure
