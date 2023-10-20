#!/bin/bash

getPaneTTY() {
	tmux display-message -p "#{pane_tty}"
}

getTmuxSock() {
	output="$(tmux display-message -p 'ps -E -o comm= -o state= -o args= -t #{pane_tty}')"

	eval "$output" | grep -Eo "/tmp/tmux-nested\S+"
}

isTmux() {
	ps -o state= -o comm= -t "$(getPaneTTY)" | grep -iqE '^[^TXZ ]+ +(\\S+\\/)?tmux?$' && return 0 || return 1
}

isVim() {
	ps -o state= -o comm= -t "$(getPaneTTY)" | grep -iqE '^[^TXZ ]+ +(\\S+\\/)?g?(view|n?vim?x?)(diff)?$' && return 0 || return 1
}

isTree() {
	output="$(tmux display-message -p 'ps -E -o comm= -o state= -o args= -t #{pane_tty}')"

	eval "$output" | grep -Eqo "VIDETREE=1" && return 0 || return 1
}

paneInDir() {
	local tmuxKey="$1"
	shift
	local paneState=($@)

	echo echo
	echo "${tmuxKey}"
	echo "${paneState[@]}"

	case $tmuxKey in
	"L")
		return ${paneState[0]}
		;;
	"D")
		return ${paneState[1]}
		;;
	"U")
		return ${paneState[2]}
		;;
	"R")
		return ${paneState[3]}
		;;
	esac
}

main() {
	case $1 in
	"left")
		vimKey="h"
		tmuxKey="L"
		;;
	"down")
		vimKey="j"
		tmuxKey="D"
		;;
	"up")
		vimKey="k"
		tmuxKey="U"
		;;
	"right")
		vimKey="l"
		tmuxKey="R"
		;;
	*)
		return 123
		;;
	esac

	local fromNVIM=false

	if [[ "$2" == "true" ]]; then
		fromNVIM=true
	fi

	if ! isTree; then
		if isVim; then
			if ! $fromNVIM; then
				tmux send-keys "M-$vimKey"
				return 0
			fi
		fi
	fi

	if isTmux; then
		local localSock="$(getTmuxSock)"

		local paneState=($(tmux -S "$localSock" display-message -p "#{pane_at_left} #{pane_at_bottom} #{pane_at_top} #{pane_at_right}"))

		if paneInDir "$tmuxKey" "${paneState[@]}"; then
			tmux -S "$localSock" select-pane -$tmuxKey

			return 0
		fi
	fi

	local paneState=($(tmux display-message -p "#{pane_at_left} #{pane_at_bottom} #{pane_at_top} #{pane_at_right}"))

	if paneInDir "$tmuxKey" "${paneState[@]}"; then
		tmux select-pane -$tmuxKey
	fi

	return 0
}

main "$@" &>/tmp/temp.out
