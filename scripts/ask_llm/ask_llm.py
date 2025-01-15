import os
import sys
import json
import argparse
import subprocess
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


def _handle_run_command(ask_app_dir):
    """Execute the last saved command from conversation history."""
    history = _load_conversation_history(ask_app_dir)
    last_cmd = history.get("last_command")
    
    if not last_cmd:
        print("No previous command found")
        sys.exit(1)
        
    print(f"Executing: {last_cmd}")
    try:
        result = subprocess.run(last_cmd, shell=True, text=True, capture_output=True)
        print(result.stdout)
        if result.stderr:
            print("Errors:", result.stderr, file=sys.stderr)
        return result.returncode
    except Exception as e:
        print(f"Error executing command: {e}", file=sys.stderr)
        sys.exit(1)

def _handle_llm_query(args, ask_app_dir):
    """Handle queries to the LLM."""
    history = _load_conversation_history(ask_app_dir)
    
    oai_api_key = os.getenv("OAI_API_KEY")
    if not oai_api_key:
        print("Error: The OAI_API_KEY environment variable is not set.")
        sys.exit(1)
    
    client = OpenAI(api_key=oai_api_key)
    user_prompt = " ".join(args.prompt)
    system_prompt = _get_system_prompt("cmd" if args.cmd else "general")

    try:
        messages = [{"role": "system", "content": system_prompt}]
        messages.extend(history.get("messages", []))
        if user_prompt:
            messages.append({"role": "user", "content": user_prompt})

        cheap_model = "gpt-4-turbo"
        response = client.chat.completions.create(model=cheap_model, messages=messages)
        response_text = response.choices[0].message.content.strip()
        print(response_text)
        
        # Update history
        if user_prompt:
            history["messages"].append({"role": "user", "content": user_prompt})
        history["messages"].append({"role": "assistant", "content": response_text})
        
        # Save the command if in cmd mode
        if args.cmd:
            history["last_command"] = response_text
        
        _save_conversation_history(ask_app_dir, history)
        return 0
        
    except Exception as e:
        print(f"Error: {e}")
        return 1

def main():
    # Create app directory in user's home
    ask_app_dir = os.path.expanduser("~/.ask_llm")
    os.makedirs(ask_app_dir, exist_ok=True)

    parser = argparse.ArgumentParser(description="Ask GPT-4 a question.")
    parser.add_argument("prompt", nargs="*", help="The prompt to send to GPT-4")
    parser.add_argument(
        "-c",
        "--respond",
        action="store_true",
        help="Respond to the previous conversation",
    )
    parser.add_argument("--cmd", action="store_true", help="Get a command to execute")
    parser.add_argument("--run", action="store_true", help="Run the last generated command")
    args = parser.parse_args()

    # Handle different modes
    if args.run:
        sys.exit(_handle_run_command(ask_app_dir))
    
    # Check if a prompt argument is provided
    if not args.prompt and not args.respond:
        print("Usage: python ask.py [-c] <prompt>")
        sys.exit(1)
        
    sys.exit(_handle_llm_query(args, ask_app_dir))


if __name__ == "__main__":
    main()
