import time
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler
from openai import OpenAI
import re


class JarvisSentinel(FileSystemEventHandler):
    def __init__(self, openai_client):
        self.openai_client = openai_client
        self.trigger_string = "AI!"

    def on_modified(self, event):
        if event.is_directory:
            return

        with open(event.src_path, "r") as file:
            content = file.read()

        self.process_ai_comments(event.src_path, content)

    def find_ai_comments(self, content):
        # This regex pattern would need to be adjusted based on your specific needs
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
            stream=True
        )

        print(f"\nResponse for comment in {file_path}:")
        for chunk in response:
            if chunk.choices and chunk.choices[0].delta.content:
                content = chunk.choices[0].delta.content
                print(content, end="", flush=True)
        print()  # Add final newline


def start_file_watcher(paths_to_watch, openai_api_key):
    # Initialize OpenAI client
    openai_client = OpenAI(api_key=openai_api_key)

    # Create event handler and observer
    event_handler = JarvisSentinel(openai_client)
    observer = Observer()

    # Add paths to watch
    for path in paths_to_watch:
        observer.schedule(event_handler, path, recursive=False)

    observer.start()

    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        observer.stop()
    observer.join()


# Usage example
if __name__ == "__main__":
    OPENAI_API_KEY = "your-api-key-here"
    PATHS_TO_WATCH = ["/path/to/watch"]

    start_file_watcher(PATHS_TO_WATCH, OPENAI_API_KEY)
