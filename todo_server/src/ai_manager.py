import os
from dotenv import load_dotenv
from openai import OpenAI
from datetime import datetime

_ = load_dotenv()


class AiManager:
    def __init__(self):
        api_key = os.environ.get("OPENROUTER_API_KEY")
        if not api_key:
            raise ValueError("OPENROUTER_API_KEY environment variable not set.")
        self.client: OpenAI = OpenAI(
            base_url="https://openrouter.ai/api/v1",
            api_key=api_key,
        )

        self.model: str = "meta-llama/llama-4-maverick:free"
        self.temperature: float = 0.1

    def get_system_prompt(self, tasks: str, code_info: str):
        prompt = f"""<info>
You are programming agent that works with Todoist API.
Your goal is to read user's request (that can be in Russian)
and generate a Python script. You can assume that in enviroment
exists object `client = TodoistAPI`
<info>

<code>
Here's some info about types and methods in Todoist 
{code_info}
</code>

<tasks>
Here's an overview of user's tasks, grouped by projects, with optional due date
{tasks}
</tasks>

<date>
Today is {datetime.now().strftime("%d %b %Y %H:%M")}
</date>

<constraints>
Output ONLY Python code, that will be directly executed in Python environment
Do not care about commenting code
You should use client:TodoistAPI to work with Todoist API, that is already presented
You can also use standard Python libraries
Try to minimize code length
Each line you output MUST be a valid Python code
</constraints>
    """
        return prompt

    def get_ai_response(self, tasks: str, code_info: str, user_request: str):
        prompt = self.get_system_prompt(tasks, code_info)
        user_request = f"""<user_request>
{user_request}
</user_request>
        """.strip()
        response = self.client.chat.completions.create(
            model=self.model,
            temperature=self.temperature,
            stream=False,
            messages=[
                {"role": "system", "content": prompt},
                {"role": "user", "content": user_request},
            ],
        )
        completion: str = response.choices[0].message.content
        if completion.startswith("```") and completion.endswith("```"):
            completion = completion[3:-3]
        if completion.startswith("python"):
            completion = completion[6:]
        return completion.strip()
