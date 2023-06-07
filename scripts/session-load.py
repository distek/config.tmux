import json
import os
from dataclasses import dataclass, fields

# Broken


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


class DataClassUnpack:
    classFieldCache = {}

    @classmethod
    def instantiate(cls, classToInstantiate, argDict):
        if classToInstantiate not in cls.classFieldCache:
            cls.classFieldCache[classToInstantiate] = {
                f.name for f in fields(classToInstantiate) if f.init}

        fieldSet = cls.classFieldCache[classToInstantiate]
        filteredArgDict = {k: v for k, v in argDict.items() if k in fieldSet}
        return classToInstantiate(**filteredArgDict)


def choose(choices):
    cmd = "echo \""

    for i in range(0, len(choices)):
        cmd = cmd+choices[i]
        if i != len(choices)-1:
            cmd = cmd + "\n"

    cmd = cmd+"\""

    cmd = cmd + "| fzf"

    b = os.popen(cmd)

    return b.readlines()[0].strip("\n")


def createPanes(sessInfo: str, window: Window):
    commands = []

    first = True

    focusMe = "0"

    for p in window.panes:
        if not first:
            commands.append(
                f"tmux send-keys -t {sessInfo} splitw")

        first = False

        commands.append(
            f"tmux send-keys -t {sessInfo}.{p.index} \"cd {p.path}\" Enter")

        if p.command != "":
            commands.append(
                f"tmux send-keys -t {sessInfo}.{p.index} \"{p.command}\" Enter"
            )

        if p.current == "true":
            focusMe = p.index

        commands.append(
            f"tmux send-keys -t {sessInfo}.{p.index} C-l"
        )

    commands.append(
        f"tmux select-pane -t {sessInfo}.{focusMe}"
    )

    return commands


def createWindows(session: Session):
    commands = []

    commands.append(f"tmux new-session -d -s \"{session.name}\"")
    if len(session.windows) == 1:
        createPanes(session.windows[0])
        return

    first = True

    focusMe = "0"

    for window in session.windows:
        sessInfo = f"\"{session.name}\":{window.index}"

        if first:
            commands.append(
                f"tmux send-keys -t {sessInfo} new-window -n {window.name}")

        first = False
        createPanes(sessInfo, window)

        if window.current == "true":
            focusMe = window.index

        commands.append(
            f"tmux select-layout -t {sessInfo} \"{window.layout}\"")

    commands.append(
        f"tmux select-window -t \"{session.name}\"{focusMe}")

    for c in commands:
        print(c)


def main():
    home = os.getenv("HOME")

    sessionFiles = os.scandir(home+"/.config/tmux/sessions")

    choices = []

    sessions = {}

    for file in sessionFiles:
        f = open(file, "r")

        j = json.load(f)

        unmarsh = DataClassUnpack.instantiate(Session, j)
        sessions[unmarsh.name] = unmarsh

    for k, s in sessions.items():
        choices.append(k)

    choice = choose(choices)

    for k, s in sessions.items():
        if k == choice:
            createWindows(s)
            break


main()
