import os
from dataclasses import dataclass


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


def main():
    dirname = os.path.dirname(__file__)
    readline = os.path.join(dirname, "readline.py")

    import readline

    name = readline.readline(">")

    print(name)


main()
