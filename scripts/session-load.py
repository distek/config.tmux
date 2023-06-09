import json
import os
from dataclasses import dataclass

# Load a session file created with session-save.py into a new session and
# switch to it


@dataclass
class Pane:
    index: str
    command: str
    path: str
    current: str


@dataclass
class Window:
    index: str
    name: str
    layout: str
    current: str
    panes: list[Pane]


@dataclass
class Session:
    name: str
    windows: list[Window]


def choose(choices):
    cmd = "echo \""

    for i in range(0, len(choices)):
        cmd = cmd+choices[i]
        if i != len(choices)-1:
            cmd = cmd + "\n"

    cmd = cmd+"\""

    cmd = cmd + "| fzf"

    b = os.popen(cmd)

    lines = b.readlines()
    if len(lines) == 0:
        exit(0)

    return lines[0].strip("\n")


def createPanes(sessInfo: str, window: Window):
    commands = []

    first = True

    focusMe = "0"

    for p in window.panes:
        pane = Pane(**p)

        if not first:
            commands.append(
                f"tmux splitw -t {sessInfo} ")

        first = False

        commands.append(
            f"tmux send-keys -t {sessInfo}.{pane.index} \"cd {pane.path}\" Enter")

        if pane.command != "":
            commands.append(
                f"tmux send-keys -t {sessInfo}.{pane.index} \"{pane.command}\" Enter"
            )

        if pane.current == "true":
            focusMe = pane.index

        commands.append(
            f"tmux send-keys -t {sessInfo}.{pane.index} C-l"
        )

    commands.append(
        f"tmux select-pane -t {sessInfo}.{focusMe}"
    )

    return commands


def createWindows(session: Session):
    commands = []

    commands.append(f"tmux new-session -d -s \"{session.name}\"")
    if len(session.windows) == 1:
        sessInfo = f"\"{session.name}\":1"
        window = Window(**session.windows[0])
        commands = commands + createPanes(sessInfo, window)
    else:
        first = True

        focusMe = "0"

        for w in session.windows:
            window = Window(**w)

            sessInfo = f"\"{session.name}\":{window.index}"

            if not first:
                commands.append(
                    f"tmux new-window -t {sessInfo} -n {window.name}")

            first = False
            commands = commands + createPanes(sessInfo, window)

            if window.current == "true":
                focusMe = window.index

            commands.append(
                f"tmux select-layout -t {sessInfo} \"{window.layout}\"")

        commands.append(
            f"tmux select-window -t \"{session.name}\":{focusMe}")

    if os.getenv("TMUX") != "":
        commands.append(
            f"tmux switch-client -t \"{session.name}\"")
    else:
        commands.append(
            f"tmux attach -t \"{session.name}\"")

    for c in commands:
        if os.system(c) != 0:
            print(f"Failure on: {c}")
            exit(1)


def main():
    home = os.getenv("HOME")

    sessionFiles = os.scandir(home+"/.config/tmux/sessions")

    choices = []

    sessions = {}

    for file in sessionFiles:
        f = open(file, "r")

        j = json.load(f)

        unmarsh = Session(**j)
        sessions[unmarsh.name] = unmarsh

    for k, s in sessions.items():
        choices.append(k)

    choice = choose(choices)

    for k, s in sessions.items():
        if k == choice:
            createWindows(s)

            break


main()
