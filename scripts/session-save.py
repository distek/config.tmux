import os
import json
import platform

# Save current tmux session as a json file to load later


def runCmd(cmd: str) -> str:
    b = os.popen(cmd)

    lines = b.readlines()
    if len(lines) == 0:
        exit(0)

    return lines


def main():
    sessionPath = f'{os.getenv("HOME")}/.config/tmux/sessions'
    if not os.path.isdir(sessionPath):
        os.makedirs(sessionPath, 0o750, True)

    name = input("Session name: ")

    winLines = runCmd(
        'tmux list-windows -F "{\\"index\\":\\"#{window_index}\\",\\"name\\":\\"#{window_name}\\",\\"layout\\":\\"#{window_layout}\\",\\"current\\":\\"#{window_active}\\"}"')

    windows = []
    for line in winLines:
        wj = json.loads(line.strip("\n"))

        paneLines = runCmd(
            f'tmux list-panes -t {wj["index"]} -F "{{\\"index\\":\\"#{{pane_index}}\\",\\"panePID\\":\\"#{{pane_pid}}\\",\\"path\\":\\"#{{pane_current_path}}\\",\\"current\\":\\"#{{pane_active}}\\"}}"')

        panes = []
        for p in paneLines:
            pj = json.loads(p.strip("\n"))

            command = ""
            if pj["panePID"] != "":
                system = platform.system()
                if system == "Linux":
                    c = runCmd(
                        f'ps -o command --ppid {pj["panePID"]}')
                    if len(c) > 1:
                        command = c[1].strip("\n")
                elif system == "Darwin":
                    c = runCmd(
                        f'ps -o command -p $(pgrep -P {pj["panePID"]} | tail -n1)')
                    if len(c) > 1:
                        command = c[1].strip("\n")
                else:
                    print("No Wand0z support")
                    exit(1)

            panes.append({"index": pj["index"], "command": command,
                         "path": pj["path"], "current": pj["current"]})

        wj["panes"] = panes

        windows.append(wj)

    session = {"name": name, "windows": windows}
    file = open(f"{sessionPath}/{name}.json", "w")

    json.dump(session, file)


main()
