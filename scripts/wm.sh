#!/usr/bin/env bash

getPanes() {
    local north="n"
    local south="n"
    local east="n"
    local west="n"

    currentPane=$(tmux display-message -p "#{pane_id}")
    echo $currentPane > /dev/null

    tmux select-pane -U
    if [ ! $currentPane = $(tmux display-message -p "#{pane_id}") ]; then
        north=$(tmux display-message -p "#{pane_id}")
        tmux select-pane -D
    fi

    tmux select-pane -D
    if [ ! $currentPane = $(tmux display-message -p "#{pane_id}") ]; then
        south=$(tmux display-message -p "#{pane_id}")
        tmux select-pane -U
    fi

    tmux select-pane -L
    if [ ! $currentPane = $(tmux display-message -p "#{pane_id}") ]; then
        west=$(tmux display-message -p "#{pane_id}")
        tmux select-pane -R
    fi

    tmux select-pane -R
    if [ ! $currentPane = $(tmux display-message -p "#{pane_id}") ]; then
        east=$(tmux display-message -p "#{pane_id}")
        tmux select-pane -L
    fi

    echo "${north},${south},${east},${west}"
}

getPosition() {
    tmux display-message -p "#{pane_at_top}#{pane_at_bottom}#{pane_at_right}#{pane_at_left}"
}

getLocalPane() {
    tmux list-panes | grep "$1" | cut -d':' -f1
}

moveRight() {
    neighbors=($(getPanes | sed 's/,/\ /g'))
    position=$(getPosition)

    currentWindow=$(tmux display-message -p "#{window_id}")

    echo $currentWindow > /dev/null

    case $position in
        0111 | 1101 | 1110 | 1011 | 0101 | 1010)
            # 0111 (single pane on bottom)
            # 1101 (singel pane on left)
            # 1110 (singel pane on right)

            tmux break-pane

            currentPane=$(tmux display-message -p "#{pane_id}")

            tmux join-pane -f -h -s ${currentPane} -t ${currentWindow}
            ;;
        1001 | 1100 | 1101)
            if [ ! ${neighbors[2]} = n ]; then
                tmux swap-pane -d -s .$(tmux display-message -p "#{pane_id}") -t $(getLocalPane ${neighbors[2]})
            fi
            ;;
    esac
}

moveLeft() {
    neighbors=($(getPanes))
    position=$(getPosition)

    currentWindow=$(tmux display-message -p "#{window_id}")

    echo $currentWindow > /dev/null

    case $position in
        0111 | 1101 | 1110 | 1011 | 1010)
            # 0111 (single pane on bottom)
            # 1101 (singel pane on left)

            tmux break-pane

            currentPane=$(tmux display-message -p "#{pane_id}")

            tmux join-pane -f -b -h -s ${currentPane} -t ${currentWindow}
    esac
}

moveDown() {
    neighbors=($(getPanes))
    position=$(getPosition)

    currentWindow=$(tmux display-message -p "#{window_id}")

    echo $currentWindow > /dev/null

    case $position in
        1011 | 1101 | 1110)
            # 0111 (single pane on bottom)
            # 1101 (singel pane on left)
            # 1110 (singel pane on right)

            tmux break-pane

            currentPane=$(tmux display-message -p "#{pane_id}")

            tmux join-pane -f -v -s ${currentPane} -t ${currentWindow}
    esac
}

moveUp() {
    neighbors=($(getPanes))
    position=$(getPosition)

    currentWindow=$(tmux display-message -p "#{window_id}")

    echo $currentWindow > /dev/null

    case $position in
        1011 | 1101 | 1110 | 0111)
            # 0111 (single pane on bottom)
            # 1101 (singel pane on left)
            # 1110 (singel pane on right)

            tmux break-pane

            currentPane=$(tmux display-message -p "#{pane_id}")

            tmux join-pane -f -b -v -s ${currentPane} -t ${currentWindow}
    esac
}

case $1 in
    down) moveDown;;
    up) moveUp;;
    right) moveRight;;
    left) moveLeft;;
    getPanes) getPanes;;
esac

