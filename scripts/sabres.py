#!/usr/bin/env python3
import yaml
import subprocess
import os
import sys
import threading
import time
import logging
import signal
from datetime import datetime

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
    return sys.stdout.isatty()


USE_COLORS = supports_color()


class Logger:
    def __init__(self, debug_mode=False):
        self.debug_mode = debug_mode
        logging.basicConfig(
            level=logging.DEBUG if debug_mode else logging.INFO,
            format="%(asctime)s.%(msecs)03d [%(levelname)s] ⚔️: %(message)s",
            datefmt="%H:%M:%S",
        )

    def debug(self, msg):
        if self.debug_mode:
            logging.debug(msg)

    def info(self, msg, color=None):
        if color and USE_COLORS:
            msg = f"{color}{msg}{Colors.RESET}"
        logging.info(msg)

    def error(self, msg):
        logging.error(colored(msg, Colors.RED))

    def success(self, msg):
        logging.info(colored(msg, Colors.GREEN))


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
    def __init__(self, config_file: str, logger: Logger):
        self.logger = logger

        self.logger.info("dev sabres starting up... ⚔️⚔️⚔️", Colors.BOLD)
        self.logger.debug(f"Initializing SabresManager with config file: {config_file}")

        with open(config_file, "r") as f:
            config_dict = yaml.safe_load(f)

        self.logger.debug(f"Loaded configuration: {config_dict}")
        self.config = ComposeSabres.from_dict(config_dict)
        self.logger.debug(f"Parsed configuration: {self.config}")
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
                # not using logger to avoid double prefixing
                sys.stdout.write(f"{prefix}{line.decode('utf-8')}")
                sys.stdout.flush()

    def _start_sabre(self, name, config, color):
        self.logger.debug(f"Starting sabre '{name}' with config: {config}")
        self.logger.info(f"Starting {name}...", color)

        cwd = os.path.abspath(os.path.expanduser(config.directory))
        self.logger.debug(f"Working directory for '{name}': {cwd}")

        env = os.environ.copy()
        if config.environment:
            self.logger.debug(
                f"Adding environment variables for '{name}': {config.environment}"
            )
            env.update(config.environment)

        # Create the shell command that sources your shell's RC file and then runs the command
        shell_setup = "source ~/.zshrc || source ~/.bashrc"

        for cmd in config.commands:
            self.logger.debug(f"Executing command for '{name}': {cmd}")
            full_cmd = f"{shell_setup} && {cmd}"
            process = subprocess.Popen(
                full_cmd,
                shell=True,
                executable="/bin/zsh",
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
                    self.logger.error(f"[{name}] Command failed: {cmd}")
                    return False

        return True

    def _start_all(self):
        self.logger.debug("Starting all services")
        dependencies = {}
        for name, config in self.config.sabres.items():
            self.logger.debug(f"Processing service '{name}' with config: {config}")
            dependencies[name] = set(config.depends_on) if config.depends_on else set()
        self.logger.debug(f"Dependency graph: {dependencies}")

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
                self.logger.error(
                    "Error: Circular dependency detected or services failed to start"
                )
                self._stop_all()
                return

            time.sleep(0.5)  # Small delay between starting services

        self.logger.success("All services started successfully!")

    def _stop_all(self):
        self.logger.info("Gracefully stopping all services...", Colors.RED)

        # Send SIGINT (Ctrl-C) to all processes
        for name, process in self.processes.items():
            if process.poll() is None:  # Process is still running
                self.logger.debug(f"Sending SIGINT to process '{name}'")
                self.logger.info(f"Stopping {name}...")
                process.send_signal(signal.SIGINT)

        # Give processes time to gracefully shutdown
        grace_period = 600
        deadline = time.time() + grace_period

        while time.time() < deadline:
            still_running = [
                name for name, p in self.processes.items() if p.poll() is None
            ]
            if not still_running:
                break
            time.sleep(0.5)

        # Force kill any remaining processes
        for name, process in self.processes.items():
            if process.poll() is None:
                self.logger.debug(
                    f"Process '{name}' did not stop gracefully, forcing kill"
                )
                process.kill()
                process.wait()

        self.logger.info("All services stopped", Colors.YELLOW)

    def run(self):
        try:
            self._start_all()

            # Keep the main thread alive until Ctrl+C
            while not self.stop_event.is_set():
                time.sleep(1)

        except KeyboardInterrupt:
            self.logger.info("Encountered Ctrl-C keyboard interrupt!", Colors.RED)
            pass
        finally:
            self._stop_all()


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: dev-compose.py <config.yml> [--debug]")
        sys.exit(1)

    debug_mode = "--debug" in sys.argv
    if debug_mode:
        sys.argv.remove("--debug")

    logger = Logger(debug_mode)
    manager = SabresManager(sys.argv[1], logger)
    manager.run()
