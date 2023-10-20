#!/bin/bash

trap closer SIGINT SIGTERM SIGHUP

closer() {
	if ! tmux -S "/tmp/tmux-nested/$dir/socket" ls | grep -q attached; then
		tmux -S "/tmp/tmux-nested/$dir/socket" kill-server
	fi
}

dir="$(basename "$PWD")"

if [ ! -d "/tmp/tmux-nested/$dir" ]; then
	mkdir -p "/tmp/tmux-nested/$dir"
fi

export NEST_TMUX=1

if tmux -S "/tmp/tmux-nested/$dir/socket" ls &>/dev/null; then
	tmux -S "/tmp/tmux-nested/$dir/socket" a
else
	tmux -S "/tmp/tmux-nested/$dir/socket" new
fi
