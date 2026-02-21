import os

from anthropic import Anthropic
from dotenv import load_dotenv

# Prefer .env from the private folder `donotcheckin-personalkeyinfo` (one level up)
base_dir = os.path.dirname(__file__)
private_env_dir = os.path.abspath(os.path.join(base_dir, "..", "donotcheckin-personalkeyinfo"))
dotenv_path = os.path.join(private_env_dir, ".env")
if os.path.exists(dotenv_path):
    load_dotenv(dotenv_path)
    print(f"Loaded environment from: {dotenv_path}")
else:
    # Fallback to default search locations
    load_dotenv()
    print("Loaded environment from default locations (no private .env found)")

LLM_API_KEY = os.environ.get("LLM_API_KEY")
if not LLM_API_KEY:
    raise ValueError("LLM_API_KEY environment variable is not set. Please add it to your .env file.")
MODEL = os.environ.get("LLM_MODEL", "claude-sonnet-4-20250514")
anthropic_client = Anthropic(api_key=LLM_API_KEY)
#print(anthropic_client.models.list())  # List available models to verify connection and API key validity

print("Welcome to your AI Assistant. Type 'goodbye' to quit.")
print("Testing connection to Anthropic API... and model is set to:", MODEL)



while True:
    prompt = input("You: ")
    if prompt.lower() == "goodbye":
        print("AI Assistant: Goodbye!")
        break
    message = anthropic_client.messages.create(
        max_tokens=1024,
        system="You are a helpful assistant.",
        messages=[
            {
                "role": "user",
                "content": prompt,
            }
        ],
        model=MODEL,
    )
    for response in message.content:
        print(f"Assistant: {response.text}")
