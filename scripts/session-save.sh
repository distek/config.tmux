#!/usr/bin/env bash

contains() {
	if echo "$1" | grep "$2" &>/dev/null; then
		return 0
	fi

	return 1
}

if [ ! -d ~/.config/tmux/sessions/ ]; then
	mkdir ~/.config/tmux/sessions/
fi

read -p "Session name: " SESSION_NAME

if [ -z $SESSION_NAME ]; then
	exit
fi

sessionFile="$HOME/.config/tmux/sessions/${SESSION_NAME}.json"

windows=($(tmux list-windows |
	sed 's#^\([0-9+]\):#\1#g' |
	sed "s#\[layout \(.*\)\]#\1#g" |
	sed 's#(\([0-9+]\)\ panes)#\1#g' |
	awk '{print "index="$1"|name="$2"|winCount="$3"|layout="$5}'))

echo -n "[" >"$sessionFile"

insert() {
	echo -n "\"$1\":\"$2\"" >>"$sessionFile"
}

insComma() {
	echo -n "," >>"$sessionFile"
}

total=${#windows[@]}

count=0
current="1"
for i in "${windows[@]}"; do
	count=$(((count + 1)))

	echo -n "{" >>"$sessionFile"
	eval $(echo "$i" | sed 's/|/\n/g')

	insert index $index
	insComma

	insert name "$(echo $name | sed 's/\*//')"
	insComma

	insert winCount $winCount
	insComma

	insert layout $layout
	insComma

	# Current window
	if contains "$name" "\*"; then
		insert "current" "true"
	else
		insert "current" "false"
	fi

	echo -n "}" >>"$sessionFile"

	if ((count != total)); then
		insComma
	fi
done

echo "]" >>"$sessionFile"
