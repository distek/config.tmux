#!/usr/bin/env bash

IFS=$'\n'
windows=($(tmux list-windows))

windows+=("new window")

windowChoice=$(for i in ${windows[@]}; do
	echo $i
done | fzf \
	--header="Move to..." \
	--header-first \
	--layout=reverse \
	--bind "esc:reload(echo)" \
	--bind esc:abort)

if [ $windowChoice = "new window" ]; then
	tmux break-pane
	exit
fi

windowChoice=$(echo $windowChoice | cut -d':' -f1)

if [ ! $windowChoice = "" ]; then
	splitChoice=$(printf "%s\n%s\n" "horiz ─" "vert  │" | fzf \
		--header="Split..." \
		--header-first \
		--layout=reverse \
		--bind "esc:reload(echo)" \
		--bind esc:abort)

	case $splitChoice in
	horiz*) splitChoice="-v" ;;
	vert*) splitChoice="-h" ;;
	esac

	if [ ! $splitChoice = "" ]; then
		tmux join-pane $splitChoice -s $(tmux display-message -p "#{pane_id}") -t :${windowChoice}
	fi
fi
