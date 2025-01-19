import os
import sys
import json
import argparse
import subprocess

from datetime import datetime

# from openai import OpenAI # lets use Groq fro now
from groq import Groq
from dotenv import load_dotenv

load_dotenv()  # take environment variables from .env.


def _get_history_file_name(ask_app_dir):
    yyyymmdd = datetime.now().strftime("%Y%m%d")
    return os.path.join(ask_app_dir, f"conversation_history_{yyyymmdd}.json")


def _load_conversation_history(args, ask_app_dir):
    read_start_time = datetime.now()
    history_file = _get_history_file_name(ask_app_dir)
    if os.path.exists(history_file):
        with open(history_file, "r") as f:
            res = json.load(f)
    else:
        res = {"messages": [], "last_command": ""}

    if args.time:
        read_end_time = datetime.now()
        print(f"INFO: ⏱️  History read took: {read_end_time - read_start_time}")

    return res


def _get_wut_cmd_and_resp(ask_app_dir):
    wut_file = os.path.join(ask_app_dir, "wut_command.log")
    if os.path.exists(wut_file):
        with open(wut_file, "r") as f:
            return f.read()
    return ""


def _get_wut_message(ask_app_dir):
    return f"""
        <context>
        The latest command that was run executed in the terminal is included in the below block.
        The first line is the command that was executed. Any subsequent lines are the output of the command.
        If the output appears to be an error message, please provide context around the error based on the command and output, and how to resolve or debug the error.
        </context>
        <command-and-output>
        {_get_wut_cmd_and_resp(ask_app_dir)}
        </command-and-output>
    """


def _save_conversation_history(ask_app_dir, history):
    history_file = _get_history_file_name(ask_app_dir)
    with open(history_file, "w") as f:
        json.dump(history, f, indent=2)


def _get_system_prompt(mode="general"):
    default = """
        You are J.A.R.V.I.S. (Just a Rather Very Intelligent System), aka Jarvis. You previously only worked for Tony Stark, aka Iron Man, but you now also help software engineers. You are a helpful AI assitant with a depth of software engineering knowledge. Always respond with canoncial, idomatic, and pragmatic code when appropriate.

        The person you are speaking with is a software engineer. They are using a computer running MacOS. They run commands in a zsh shell. They use neovim as their main text editor. Use that information to help you respond.
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


def _handle_run_command(args, ask_app_dir):
    """Execute the last saved command from conversation history."""
    history = _load_conversation_history(args, ask_app_dir)
    last_cmd = history.get("last_command")

    if not last_cmd:
        print("WARN: No previous command found")
        sys.exit(1)

    print(f"INFO: Executing: {last_cmd}")
    try:
        result = subprocess.run(last_cmd, shell=True, text=True, capture_output=True)
        print(result.stdout)
        if result.stderr:
            print("ERROR: Errors:", result.stderr, file=sys.stderr)
        return result.returncode
    except Exception as e:
        print(f"ERROR: Error executing command: {e}", file=sys.stderr)
        sys.exit(1)


def _handle_llm_query(args, ask_app_dir):
    """Handle queries to the LLM."""
    history = _load_conversation_history(args, ask_app_dir)

    # oai_api_key = os.getenv("OAI_API_KEY")
    groq_api_key = os.getenv("GROQ_API_KEY")
    if not groq_api_key:
        print("ERROR: The GROQ_API_KEY environment variable is not set.")
        sys.exit(1)

    # client = OpenAI(api_key=oai_api_key)
    client = Groq(api_key=groq_api_key)
    user_prompt = " ".join(args.prompt)
    system_prompt = _get_system_prompt("cmd" if args.cmd else "general")

    messages = []
    if args.chat:
        hist = history.get("messages", [])
        if len(hist) > args.chat:
            hist = hist[-args.chat :]
        messages.extend(hist)
    messages.append({"role": "system", "content": system_prompt})
    if user_prompt:
        messages.append({"role": "user", "content": user_prompt})
    elif args.wut:
        messages.append({"role": "user", "content": _get_wut_message(ask_app_dir)})

    if args.debug:
        print("-- DEBUG --")
        print(json.dumps(messages, indent=2))
        print("-- DEBUG --")

    try:
        # cheap_model = "gpt-4-turbo"
        cheap_model = "llama-3.3-70b-versatile"

        llm_start_time = datetime.now()

        response = client.chat.completions.create(
            model=cheap_model,
            messages=messages,
            stream=True,  # Enable streaming
        )

        # Collect the full response while streaming
        collected_response = []
        for chunk in response:
            if chunk.choices[0].delta.content:
                content = chunk.choices[0].delta.content
                print(content, end="", flush=True)
                collected_response.append(content)

        # Add a newline after streaming completes
        print()

        if args.time:
            llm_end_time = datetime.now()
            print(f"INFO: ⏱️  LLM response took: {llm_end_time - llm_start_time}")

        full_response = "".join(collected_response)

        if args.debug:
            print("-- DEBUG --")
            print(f"{response.response.status_code=}")
            print(f"{response.response.headers=}")
            print("-- DEBUG --")

        save_start_time = datetime.now()

        if user_prompt:
            history["messages"].append({"role": "user", "content": user_prompt})
        history["messages"].append({"role": "assistant", "content": full_response})
        if args.cmd:
            history["last_command"] = full_response.strip()

        _save_conversation_history(ask_app_dir, history)

        if args.time:
            save_end_time = datetime.now()
            print(f"INFO: ⏱️  History save took: {save_end_time - save_start_time}")
        return 0

    except Exception as e:
        print(f"ERROR: {e}")
        return 1


def main():
    ask_app_dir = os.path.expanduser("~/.jarvis")
    os.makedirs(ask_app_dir, exist_ok=True)

    parser = argparse.ArgumentParser(
        description="I am J.A.R.V.I.S. (Just a Rather Very Intelligent System), aka Jarvis. Ask me a question."
    )
    parser.add_argument("prompt", nargs="*", help="The prompt to send to the LLM")
    parser.add_argument("--cmd", action="store_true", help="Get a command to execute")
    parser.add_argument(
        "--run", action="store_true", help="Run the last generated command"
    )
    parser.add_argument(
        "--chat", type=int, default=0, help="Pass in the last n messages to the LLM"
    )
    parser.add_argument(
        "--wut",
        action="store_true",
        help="Pass in the last wut command and response to get help with an error message",
    )
    parser.add_argument(
        "--debug",
        action="store_true",
        help="Print the full request and response from the LLM",
    )
    parser.add_argument(
        "--time",
        action="store_true",
        help="Print the time it took to execute the command",
    )
    args = parser.parse_args()

    if args.run:
        sys.exit(_handle_run_command(args, ask_app_dir))

    sys.exit(_handle_llm_query(args, ask_app_dir))


if __name__ == "__main__":
    main()
