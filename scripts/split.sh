#!/bin/bash

case $1 in
4)
	tmux split-window -h
	tmux split-window -v
	tmux select-pane -L
	tmux split-window -v
	tmux select-pane -U
	;;
esac
