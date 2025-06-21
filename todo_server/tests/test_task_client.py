import pytest
from datetime import date
from unittest.mock import Mock, MagicMock
from todoist_api_python.models import Task as TodoistTask, Due

from src.task_client import TaskClient, Task
from src.todoist_manager import TodoistManagerSyncEndpoint


def test_add_task():
    # Mock the read-only client
    mock_todoist_ro = Mock(spec=TodoistManagerSyncEndpoint)
    
    # Create TaskClient instance
    client = TaskClient(mock_todoist_ro)
    
    # Mock the todoist API response
    # mock_due = Due(date="2025-06-21", is_recurring=False, lang="en", string="Jun 21")
    # mock_todoist_task = TodoistTask(
    #     id="test_task_id",
    #     content="задача",
    #     project_id="2316809606",
    #     priority=1,
    #     due=mock_due
    # )
    # 
    # # Mock the add_task method to return our mock task
    # client.todoist.add_task = MagicMock(return_value=mock_todoist_task)
    
    # Call the method under test
    print('lul')
    result = client.add_task(
        content='lul',
        # project_id='2316809606',
        project_id='2347646916',
        due_date=date(2025, 6, 21)
    )
    
    # Verify the todoist API was called with correct parameters
    client.todoist.add_task.assert_called_once_with(
        'задача',
        project_id='2316809606',
        due_date=date(2025, 6, 21),
        due_datetime=None,
        priority=None
    )
    
    # Verify the returned Task object
    assert isinstance(result, Task)
    assert result.id == "test_task_id"
    assert result.content == "задача"
    assert result.project_id == "2316809606"
    assert result.priority == 1
    assert result.due == date(2025, 6, 21)
