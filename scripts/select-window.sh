#!/bin/bash

windows=($(tmux list-windows | cut -d':' -f1))

for i in ${windows[@]}; do
	if [[ "$i" == "$1" ]]; then
		tmux select-window -t "$1"
		exit 0
	fi
done

tmux new-window -t "$1"
