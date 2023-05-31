#!/bin/bash

windows=($(tmux list-windows | cut -d':' -f1))

for i in ${windows[@]}; do
	if [[ "$i" == "$1" ]]; then
		tmux join-pane -t "$1"
		exit 0
	fi
done

tmux break-pane -t "$1"
