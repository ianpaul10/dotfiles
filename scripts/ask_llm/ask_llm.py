import os
import sys
import json
import argparse
from openai import OpenAI

from dotenv import load_dotenv

load_dotenv()  # take environment variables from .env.


def _load_conversation_history(ask_app_dir):
    history_file = os.path.join(ask_app_dir, "conversation_history.json")
    if os.path.exists(history_file):
        with open(history_file, "r") as f:
            return json.load(f)
    return []


def _save_conversation_history(ask_app_dir, history):
    history_file = os.path.join(ask_app_dir, "conversation_history.json")
    with open(history_file, "w") as f:
        json.dump(history, f)


def _get_system_prompt(mode="general"):
    default = """
        You are J.A.R.V.I.S. (Just a Rather Very Intelligent System), aka Jarvis. You previously only worked for Tony Stark, aka Iron Man, but you now also help software engineers. You are a helpful AI assitant with a depth of software engineering knowledge, and always respond with canoncial and idomatic code when appropriate.
        """
    prompts = {
        "general": """
        Provide clear, concise answers.
        You can use markdown formatting when appropriate.
        """,
        "cmd": """
        Return only the command to be executed as a raw string.
        Do not include any formatting tokens such as ` or ```. No yapping. No markdown. No fenced code blocks. Do not hallucinate.
        What you return will be passed to subprocess.check_output() directly.
        """,
    }
    return default + prompts.get(mode, prompts["general"])


def main():
    # ask_app_dir = os.path("~/code/dotfiles/scripts/ask_llm")

    parser = argparse.ArgumentParser(description="Ask GPT-4 a question.")
    parser.add_argument("prompt", nargs="*", help="The prompt to send to GPT-4")
    parser.add_argument(
        "-c",
        "--respond",
        action="store_true",
        help="Respond to the previous conversation",
    )
    parser.add_argument("--cmd", action="store_true", help="Get a command to execute")
    args = parser.parse_args()

    # Check if a prompt argument is provided
    if not args.prompt and not args.respond:
        print("Usage: python ask.py [-c] <prompt>")
        sys.exit(1)

    oai_api_key = os.getenv("OAI_API_KEY")
    if not oai_api_key:
        print("Error: The OAI_API_KEY environment variable is not set.")
        sys.exit(1)
    client = OpenAI(api_key=oai_api_key)

    user_prompt = " ".join(args.prompt)
    system_prompt = _get_system_prompt("cmd" if args.cmd else "general")

    try:
        # Prepare messages for the API call
        messages = [{"role": "system", "content": system_prompt}]
        # messages.extend(conversation_history)
        if user_prompt:
            messages.append({"role": "user", "content": user_prompt})

        # Make a request to OpenAI's GPT-4 model in chat mode
        # cheap_model = "gpt-3.5-turbo"
        cheap_model = "gpt-4-turbo"
        # default_model = "gpt-4o"
        response = client.chat.completions.create(model=cheap_model, messages=messages)

        response_text = response.choices[0].message.content.strip()
        print(response_text)

    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
