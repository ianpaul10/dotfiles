import time
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler
from openai import OpenAI
import re


class JarvisSentinel(FileSystemEventHandler):
    def __init__(self, openai_client, debug=False):
        self.openai_client = openai_client
        self.trigger_string = "AI!"
        self.debug = debug

    def on_modified(self, event):
        if self.debug:
            print(f"File modified: {event.src_path}")
            print(f"Is directory: {event.is_directory}")

        if event.is_directory:
            return

        try:
            with open(event.src_path, "r") as file:
                content = file.read()
                if self.debug:
                    print(f"Read {len(content)} characters from file")
        except Exception as e:
            print(f"Error reading file: {e}")
            return

        self.process_ai_comments(event.src_path, content)

    def find_ai_comments(self, content):
        # Matches any line containing the trigger string
        pattern = f".*{self.trigger_string}.*$"
        return re.findall(pattern, content, re.MULTILINE)

    def process_ai_comments(self, file_path, content):
        comments = self.find_ai_comments(content)
        cleaned_comments = []
        for comment in comments:
            cleaned_comments.append(comment.replace(self.trigger_string, "").strip())

        # Add file context
        context = f"""
            <file>
            {file_path}
            </file>

            <context>
            {cleaned_comments}
            </context>

            <file_content>
            {content}
            </file_content>
            """

        response = self.openai_client.chat.completions.create(
            model="gpt-4-turbo-preview",
            messages=[{"role": "user", "content": context}],
            stream=True,
        )

        print(f"\nResponse for comment in {file_path}:")
        collected_resp = []
        for chunk in response:
            if chunk.choices and chunk.choices[0].delta.content:
                content = chunk.choices[0].delta.content
                print(content, end="", flush=True)
                collected_resp.append(content)
        print()  # Add final newline


def start_file_watcher(paths_to_watch, openai_api_key, debug=False):
    openai_client = OpenAI(api_key=openai_api_key)

    event_handler = JarvisSentinel(openai_client, debug=debug)
    observer = Observer()

    for path in paths_to_watch:
        observer.schedule(event_handler, path, recursive=False)

    observer.start()

    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        observer.stop()
        print("GSD")
    observer.join()


# Usage example
if __name__ == "__main__":
    import argparse
    import os
    from dotenv import load_dotenv

    load_dotenv()  # take environment variables from .env

    parser = argparse.ArgumentParser(description="Watch directory for AI comments")
    parser.add_argument(
        "directory",
        nargs="?",
        default=".",
        help="Directory to watch (default: current directory)",
    )
    parser.add_argument(
        "--debug",
        action="store_true",
        help="Enable debug logging",
    )
    args = parser.parse_args()

    # Expand user path and make absolute
    watch_dir = os.path.abspath(os.path.expanduser(args.directory))
    if not os.path.exists(watch_dir):
        print(f"Error: Directory '{watch_dir}' does not exist")
        exit(1)

    OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")
    if not OPENAI_API_KEY:
        print("Error: OPENAI_API_KEY environment variable not set")
        exit(1)

    print(f"Watching directory: {watch_dir}")
    if args.debug:
        print("Debug mode enabled")
    start_file_watcher([watch_dir], OPENAI_API_KEY, debug=args.debug)
