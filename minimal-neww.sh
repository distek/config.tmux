#!/bin/bash

if ! tmux -S "/tmp/tmux-vim_${1}" ls &>/dev/null; then
	$HOME/.config/tmux/minimal.sh "${1}"
fi

tmux -S "/tmp/tmux-vim_${1}" new-session
