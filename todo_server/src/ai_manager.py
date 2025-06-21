import os
from typing import final
from dotenv import load_dotenv
from loguru import logger
from openai import OpenAI
from datetime import datetime
from openai.types.chat import ChatCompletionMessageParam

_ = load_dotenv()


@final
class AiManager:
    def __init__(self):
        api_key = os.environ.get("OPENROUTER_API_KEY")
        if not api_key:
            logger.error("OPENROUTER_API_KEY environment variable not set.")
            raise ValueError("OPENROUTER_API_KEY environment variable not set.")
        self.client: OpenAI = OpenAI(
            base_url="https://openrouter.ai/api/v1",
            api_key=api_key,
            timeout=10.0,
        )

        self.model: str = "meta-llama/llama-4-maverick"
        # self.model = "qwen/qwen-2.5-coder-32b-instruct"
        # self.model = "anthropic/claude-3.7-sonnet"
        self.fallbacks: list[str] = [
            "deepseek/deepseek-chat-v3-0324",
            "anthropic/claude-sonnet-4",
            "google/gemini-2.0-flash-001",
            "google/gemini-2.5-pro-exp-03-25:free",
        ]
        self.temperature: float = 0.0
        self.max_tokens = 10000

    def _call_ai(
        self,
        system_prompt: str,
        user_request: str,
        model_override: str | None = None,
        history: list[ChatCompletionMessageParam] | None = None,
    ) -> str:
        models = [self.model] + self.fallbacks
        if model_override is not None:
            models[0] = model_override
        for model in models:
            try:
                logger.info(f"Trying model: {model}")
                extra_body = None
                if model == "meta-llama/llama-4-maverick":
                    extra_body = {"provider": {"order": ["Fireworks"]}}
                if model == "qwen/qwen-2.5-coder-32b-instruct":
                    extra_body = {
                        "provider": {"order": ["Lambda", "Together", "Fireworks"]}
                    }
                if model == "deepseek/deepseek-chat-v3-0324":
                    extra_body = {
                        "provider": {"order": ["Lambda", "Novita", "DeepInfra"]}
                    }
                if history is None:
                    history = []
                messages: list[ChatCompletionMessageParam] = [
                    {"role": "system", "content": system_prompt}
                ]
                messages.extend(history)
                messages.append({"role": "user", "content": user_request})

                response = self.client.chat.completions.create(
                    model=model,
                    temperature=self.temperature,
                    stream=False,
                    messages=messages,
                    # timeout=httpx.Timeout(10.0),
                    extra_body=extra_body,
                    max_completion_tokens=self.max_tokens,
                )
                completion = response.choices[0].message.content
                assert isinstance(completion, str)
                logger.info(f"Got completion from {model}")
                return completion.strip()
            except Exception as e:
                logger.warning(f"Error calling AI model {model}: {e}")
                continue
        logger.error("Could not get response from any AI model after trying all fallbacks.")
        raise Exception("Could not call AI")

    def get_code_system_prompt(self, tasks: str, code_info: str):
        prompt = f"""<info>
You are programming agent that works with Tasks API.
Your goal is to read user's request (that can be in Russian)
and generate a Python script. You can assume that in enviroment
exists object `client = TasksAPI`
<info>

<code>
Here's specification about methods in Tasks API
ALWAYS make sure your code correctly uses it's methods and parameters, do not invent your own interface
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
Do not comment code
You should use client:TasksAPI to work with Tasks API, that is already presented
Try to minimize code length and number of api calls
Don't define new functions
Don't use if __name__ == "__main__"
To get date,timedelta,datetime classes from datetime use client.get_date_cls(), client.get_timedelta_cls(), client.get_datetime_cls()
If variables can be data or datetime objects, do not compare them directly
Never import any other modules
Each line you output MUST be a valid Python code
Always print() the answer of interest
</constraints>
    """
        return prompt

    def get_code_ai_response(self, context: str, code_info: str, user_request: str, history=None):
        prompt = self.get_code_system_prompt(context, code_info)
        user_request = f"""<user_request>
{user_request}
</user_request>
        """.strip()
        completion = self._call_ai(
            prompt,
            user_request,
            # model_override="anthropic/claude-3.7-sonnet",
            # model_override="qwen/qwen-2.5-coder-32b-instruct",
            # model_override="google/gemini-2.0-flash-001",
            model_override="google/gemini-2.5-flash",
            # model_override="deepseek/deepseek-chat-v3-0324",
            history=history,
        )
        if completion.startswith("```"):
            completion = completion[3:]
        if completion.startswith("python"):
            completion = completion[6:]
        if completion.endswith("```"):
            completion = completion[:-3]
        completion = completion.replace("<|python_end|>", "")
        return completion.strip()

    def get_answer_ai_response(self, task: str, code: str, output: str, history=None) -> str:
        prompt = """<info>
You are given users' request, Python code and result of it's execution (stdout code output)
If code executed successfully, you should describe the result of it's execution, do not describe code in this case
If it failed, you should explain why
</info>

<constraints>
In answer try to focus on details that matter for user, like was result successful or not or what was done
Always describe code output - it's the most important part to user, but do not read project or task IDs
Try to fit the answer in one-two sentences when possible
Output response in Russian language
</constraints>

<example>
<user_request>
How many tasks I have today?
</user_request>

<code>
from datetime import datetime

def count_tasks_for_today(client):
    tasks = client.get_tasks()
    today = datetime.now().strftime('%Y-%m-%d')
    count = sum(1 for task in tasks if task.due and task.due.date == today)
    return count

print(count_tasks_for_today(client))
</code>

<output>
Successfully executed code:
2
</output>

<answer>
You have 2 tasks today
</answer>
</example>
        """.strip()
        user_request = f"""<user_request>
        {task}
        </user_request>

        <code>
        {code}
        </code>

        <output>
        {output}
        </output>
        """.strip()
        completion = self._call_ai(prompt, user_request, history=history)
        return completion
