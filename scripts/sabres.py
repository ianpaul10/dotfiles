#!/usr/bin/env python3
import yaml
import subprocess
import os
import sys
import threading
import time
import logging
import signal

from typing import Dict, List
from dataclasses import dataclass, field


# ANSI color codes
class Colors:
    RESET = "\033[0m"
    GREEN = "\033[32m"
    BLUE = "\033[34m"
    YELLOW = "\033[33m"
    MAGENTA = "\033[35m"
    CYAN = "\033[36m"
    RED = "\033[31m"
    BOLD = "\033[1m"


COLORS = [
    Colors.GREEN,
    Colors.BLUE,
    Colors.YELLOW,
    Colors.MAGENTA,
    Colors.CYAN,
    Colors.RED,
]


def supports_color():
    if os.name == "nt":
        return os.environ.get("ANSICON") is not None or "TERM" in os.environ
    else:
        return sys.stdout.isatty()


USE_COLORS = supports_color()


def colored(text, color):
    if USE_COLORS:
        return f"{color}{text}{Colors.RESET}"
    return text


@dataclass
class Sabre:
    directory: str
    commands: List[str]
    environment: Dict[str, str] = field(default_factory=dict)
    depends_on: List[str] = field(default_factory=list)


@dataclass
class ComposeSabres:
    sabres: Dict[str, Sabre] = field(default_factory=dict)

    @classmethod
    def from_dict(cls, data: dict) -> "ComposeSabres":
        services = {}
        for name, service_data in data.get("sabres", {}).items():
            services[name] = Sabre(
                directory=service_data.get("directory", "."),
                commands=service_data.get("commands", []),
                environment=service_data.get("environment", {}),
                depends_on=service_data.get("depends_on", []),
            )
        return cls(sabres=services)


class SabresManager:
    def __init__(self, config_file):
        logging.info(" ⚔️ Dev Sabres ⚔️ ")
        logging.debug(f"Initializing SabresManager with config file: {config_file}")
        with open(config_file, "r") as f:
            config_dict = yaml.safe_load(f)
        logging.debug(f"Loaded configuration: {config_dict}")
        self.config = ComposeSabres.from_dict(config_dict)
        logging.debug(f"Parsed configuration: {self.config}")
        self.processes = {}
        self.stop_event = threading.Event()

    def _output_handler(self, process, service_name, color):
        """Handle and format output from a process"""
        prefix = colored(f"[{service_name}] ", color)
        while True:
            line = process.stdout.readline()
            if not line and process.poll() is not None:
                break
            if line:
                sys.stdout.write(f"{prefix}{line.decode('utf-8')}")
                sys.stdout.flush()

    def _start_sabre(self, name, config, color):
        logging.debug(f"Starting sabre '{name}' with config: {config}")
        print(colored(f"Starting {name}...", color))

        cwd = os.path.abspath(os.path.expanduser(config.directory))
        logging.debug(f"Working directory for '{name}': {cwd}")

        env = os.environ.copy()
        if config.environment:
            logging.debug(
                f"Adding environment variables for '{name}': {config.environment}"
            )
            env.update(config.environment)

        # Create the shell command that sources your shell's RC file and then runs the command
        shell_setup = "source ~/.zshrc || source ~/.bashrc"

        for cmd in config.commands:
            logging.debug(f"Executing command for '{name}': {cmd}")
            full_cmd = f'{shell_setup} && {cmd}'
            process = subprocess.Popen(
                full_cmd,
                shell=True,
                executable='/bin/zsh',
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                cwd=cwd,
                env=env,
            )

            self.processes[name] = process

            # Start a thread to handle the output
            thread = threading.Thread(
                target=self._output_handler, args=(process, name, color)
            )
            thread.daemon = True
            thread.start()

            # If this isn't the last command, wait for it to complete
            if cmd != config.commands[-1]:
                process.wait()
                if process.returncode != 0:
                    print(colored(f"[{name}] Command failed: {cmd}", Colors.RED))
                    return False

        return True

    def _start_all(self):
        logging.debug("Starting all services")
        dependencies = {}
        for name, config in self.config.sabres.items():
            logging.debug(f"Processing service '{name}' with config: {config}")
            dependencies[name] = set(config.depends_on) if config.depends_on else set()
        logging.debug(f"Dependency graph: {dependencies}")

        started = set()
        color_index = 0

        while len(started) < len(self.config.sabres):
            progress = False

            for name, deps in dependencies.items():
                if name not in started and deps.issubset(started):
                    # All dependencies are started, we can start this service
                    config = self.config.sabres[name]
                    color = COLORS[color_index % len(COLORS)]
                    color_index += 1

                    if self._start_sabre(name, config, color):
                        started.add(name)
                        progress = True

            if not progress and len(started) < len(self.config.sabres):
                print(
                    colored(
                        "Error: Circular dependency detected or services failed to start",
                        Colors.RED,
                    )
                )
                self._stop_all()
                return

            time.sleep(0.5)  # Small delay between starting services

        print(colored("All services started successfully!", Colors.GREEN))

    def _stop_all(self):
        """Stop all running processes"""
        logging.debug("Stopping all services")
        print("\nStopping all services...")
        
        # First try SIGINT (Ctrl-C) on all processes
        for name, process in self.processes.items():
            if process.poll() is None:  # Process is still running
                logging.debug(f"Sending SIGINT to process '{name}'")
                print(f"Stopping {name}...")
                if sys.platform == "win32":
                    process.send_signal(signal.CTRL_C_EVENT)
                else:
                    process.send_signal(signal.SIGINT)

        # Give processes time to gracefully shutdown
        grace_period = 10
        deadline = time.time() + grace_period
        
        while time.time() < deadline:
            still_running = [name for name, p in self.processes.items() if p.poll() is None]
            if not still_running:
                break
            time.sleep(0.5)

        # Force kill any remaining processes
        for name, process in self.processes.items():
            if process.poll() is None:
                logging.debug(f"Process '{name}' did not stop gracefully, forcing kill")
                process.kill()
                process.wait()

        print(colored("All services stopped", Colors.YELLOW))

    def run(self):
        try:
            self._start_all()

            # Keep the main thread alive until Ctrl+C
            while not self.stop_event.is_set():
                time.sleep(1)

        except KeyboardInterrupt:
            print(colored("\nStopping services...", Colors.RED))
            pass
        finally:
            self._stop_all()


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: dev-compose.py <config.yml> [--debug]")
        sys.exit(1)

    debug_mode = "--debug" in sys.argv
    if debug_mode:
        logging.basicConfig(level=logging.DEBUG)
        sys.argv.remove("--debug")
    else:
        logging.basicConfig(level=logging.INFO)

    manager = SabresManager(sys.argv[1])
    manager.run()
