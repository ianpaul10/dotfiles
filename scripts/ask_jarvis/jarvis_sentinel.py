import time
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler
import anthropic
import re


class JarvisSentinel(FileSystemEventHandler):
    def __init__(self, claude_client):
        self.claude_client = claude_client
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

        # Send to Claude and get response
        # TODO: replace with openai api
        response = self.claude_client.messages.create(
            model="claude-3-opus-20240229",
            max_tokens=1000,
            messages=[{"role": "user", "content": context}],
        )

        print(f"\nResponse for comment in {file_path}:")
        print(response.content)


def start_file_watcher(paths_to_watch, claude_api_key):
    # Initialize Claude client
    claude_client = anthropic.Client(api_key=claude_api_key)

    # Create event handler and observer
    event_handler = JarvisSentinel(claude_client)
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
    CLAUDE_API_KEY = "your-api-key-here"
    PATHS_TO_WATCH = ["/path/to/watch"]

    start_file_watcher(PATHS_TO_WATCH, CLAUDE_API_KEY)
