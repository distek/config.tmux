#!/usr/bin/env bash

usage() {
	echo -e "$(basename $0) usage:

    $(basename $0) [-h|--help] [-s|--session customSessionFile.json]

   	-h | --help		Print this help
   	-s | --session	Specify a specific file to save the session info to (output is in JSON)
                    (default save is )

"
}

init() {
	if [ ! -d ~/.config/tmux/sessions/ ]; then
		mkdir ~/.config/tmux/sessions/
	fi

	if [ ! -z $sessionName ] && [ ! -z $customSessionFile ]; then
		echo "session-name is ignored if session-file is specified"
	fi

	if [ -z "$customSessionFile" ]; then
		if [ -z "$sessionName" ]; then
			set -o emacs
			bind '"\C-w": kill-whole-line'
			bind '"\e": "\C-w\C-d"'
			bind '"\e\e": "\C-w\C-d"'

			read -e -r -p "Session name (Esc to exit): " SESSION_NAME

			bind -r "\e" &>/dev/null

			if [ -z "$SESSION_NAME" ]; then
				exit 1
			fi
		else
			SESSION_NAME="$sessionName"
		fi

		fileSessionName="$(echo "$SESSION_NAME" | sed 's/\s/_/g')"

		sessionFile="$HOME/.config/tmux/sessions/${fileSessionName}.json"
	else
		sessionFile="$customSessionFile"
	fi

	if [ ! -f "$sessionFile" ]; then
		if ! touch "$sessionFile"; then
			exit 1
		fi
	fi
}

contains() {
	if echo "$1" | grep "$2" &>/dev/null; then
		return 0
	fi

	return 1
}

insert() {
	echo -n "\"$1\":\"$2\"" >>"$sessionFile"
}

insComma() {
	echo -n "," >>"$sessionFile"
}

main() {
	windows=($(tmux list-windows -F "index=#{window_index}|name=#{window_name}|paneCount=#{window_panes}|layout=#{window_layout}|current=#{window_active}"))

	echo -n "{" >"$sessionFile"

	echo -n "\"name\": \"$SESSION_NAME\"," >>"$sessionFile"
	echo -n "\"windows\": [" >>"$sessionFile"

	total=${#windows[@]}

	count=0
	current="1"
	for i in "${windows[@]}"; do
		count=$(((count + 1)))

		echo -n "{" >>"$sessionFile"
		eval $(echo "$i" | sed 's/|/\n/g')

		insert index "$index"
		insComma

		insert name "$(echo "$name" | sed 's/\*//')"
		insComma

		insert winCount $winCount
		insComma

		echo -n "\"panes\": [" >>"$sessionFile"
		paneCount=0
		windowPanes=($(tmux list-panes -t $index -F "#{pane_index}|#{pane_pid}|#{pane_current_path}|#{pane_active}"))
		for i in "${windowPanes[@]}"; do
			paneCount=$(((paneCount + 1)))

			echo -n "{" >>"$sessionFile"

			split=($(echo "$i" | sed 's/|/ /g'))
			insert index "${split[0]}"
			insComma

			commandWithArgs="$(ps -o command --ppid ${split[1]} | tail -n1)"
			if [[ "$commandWithArgs" == "COMMAND" ]]; then
				commandWithArgs=""
			fi

			insert command "$commandWithArgs"
			insComma

			insert path "${split[2]}"
			insComma

			if ((${split[3]} == 1)); then
				insert "current" "true"
			else
				insert "current" "false"
			fi

			echo -n "}" >>"$sessionFile"

			if ((paneCount != ${#windowPanes[@]})); then
				insComma
			fi
		done

		echo -n "]" >>"$sessionFile"
		insComma

		insert layout $layout
		insComma

		if ((current == 1)); then
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
	echo -n "}" >>"$sessionFile"
}

init "$@"
main
