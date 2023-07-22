#!/bin/bash

case $1 in
4)
	tmux split-window -c "#{pane_current_path}" -h
	tmux split-window -c "#{pane_current_path}" -v
	tmux select-pane -L
	tmux split-window -c "#{pane_current_path}" -v
	tmux select-pane -U
	;;
esac
