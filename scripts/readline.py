import sys
import termios
import tty


def getChar():
    fd = sys.stdin.fileno()
    old_settings = termios.tcgetattr(fd)
    tty.setcbreak(fd)
    ch = sys.stdin.read(1)
    termios.tcsetattr(fd, termios.TCSADRAIN, old_settings)

    return ch


def deleteWord(buf, pLen, pos, prompt: str):
    if pos == 0:
        return buf, pos

    if len(buf) == 0:
        return buf, pos

    mark = -1

    for i in range(pos-1, -1, -1):
        if i == pos-1 and buf[i] == " ":
            continue

        # TODO: Replace with isStopChar(buf[i])
        # So things like {}[].-etc
        if buf[i] == " ":
            mark = i+1
            break

    if mark == -1:
        buf = buf[pos:len(buf)]
        pos = 0
    else:
        buf = buf[0:mark]+buf[pos:len(buf)]
        pos = mark

    printReadline(buf, pLen, pos, prompt)
    return buf, pos


def printReadline(buf, pLen, pos, prompt: str):
    sys.stdout.write("\33[2K\r")
    sys.stdout.write(prompt+"".join(buf))
    sys.stdout.write(f"\33[G\33[{pLen+pos}C")
    sys.stdout.flush()


def readline(prompt: str):
    prompt = prompt+" "

    buf = []

    sys.stdout.write(prompt)
    sys.stdout.flush()

    lastWasEscape = False
    inEscSeq = False

    pos = 0

    pLen = len(prompt)

    while True:
        c = getChar()
        sys.stdin.flush()
        rawC = c.encode("utf-8")

        if inEscSeq:
            match rawC:
                # left
                case b"D":
                    if pos > 0:
                        pos = pos - 1
                        sys.stdout.write("\33[D")
                        sys.stdout.flush()

                    inEscSeq = False
                    continue
                # Down - Ignored
                case b"B":
                    inEscSeq = False
                    continue
                # Up - Ignored
                case b"A":
                    inEscSeq = False
                    continue
                # Right
                case b"C":
                    if pos < len(buf):
                        pos = pos + 1
                        sys.stdout.write("\33[C")
                        sys.stdout.flush()

                    inEscSeq = False
                    continue

                case b"\x33":
                    # Continuing escape sequence
                    continue

                case b"\x7e":
                    inEscSeq = False
                    if pos == 0:
                        continue

                    if len(buf) == pos:
                        continue

                    buf.pop(pos)
                    printReadline(buf, pLen, pos, prompt)
                    continue
                case _:
                    # unhandled
                    inEscSeq = False
                    continue

        # Escape
        match rawC:
            case b"\x1b":
                if lastWasEscape:
                    break

                lastWasEscape = True

                continue

            case b"[":
                if lastWasEscape:
                    lastWasEscape = False
                    inEscSeq = True
                    continue
            # beginning of line
            case b"\x01":
                pos = 0
                printReadline(buf, pLen, pos, prompt)
                continue

            case b"\x03":
                exit(0)

            # end of line
            case b"\x05":
                pos = len(buf)
                printReadline(buf, pLen, pos, prompt)
                continue

            # Ctrl-backspace
            case b"\x08":
                buf, pos = deleteWord(buf, pLen, pos, prompt)
                continue

            # Enter/Return
            case b"\x0a":
                sys.stdout.write("\33[2K\r")
                sys.stdout.flush()
                return "".join(buf)

            # Ctrl-u
            case b"\x0b":
                buf = buf[:pos]
                printReadline(buf, pLen, pos, prompt)
                continue

            # Ctrl-k
            case b"\x15":
                buf = buf[pos:]
                pos = 0
                printReadline(buf, pLen, pos, prompt)
                continue

            # Backspace
            case b"\x7f":
                if lastWasEscape:
                    lastWasEscape = False
                    buf, pos = deleteWord(buf, pLen, pos, prompt)

                    continue

                if pos == 0:
                    continue
                if pos <= len(buf):
                    buf.pop(pos-1)
                    pos = pos - 1

                printReadline(buf, pLen, pos, prompt)
                continue
            case _:
                buf.append(c)
                pos = pos + 1
                sys.stdout.write("\33[C\33[s\33[2K\r")
                sys.stdout.write(prompt+"".join(buf))
                sys.stdout.write("\33[u")
                sys.stdout.flush()

        import binascii
        print(binascii.hexlify(c.encode('utf-8')))
