from openai import OpenAI
import os

key = os.environ["DEEPSEEK_API_KEY"]
client = OpenAI(api_key=key, base_url="https://api.deepseek.com")

prompt = open("prompt.md").read()

response = client.chat.completions.create(
    model="deepseek-chat",
    messages=[
        {"role": "system", "content": prompt},
        {"role": "user", "content": "List favorite projects"},
    ],
    stream=False
)

print(response.choices[0].message.content)
