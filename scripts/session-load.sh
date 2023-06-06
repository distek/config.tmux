#!/usr/bin/env bash

cd "$HOME/.config/tmux/sessions"

sessionFiles=($(ls))

for i in "${sessionFiles[@]}"; do
	sessions+=("$(cat "$i" | jq '.')")
done

session="$(for i in "${sessions[@]}"; do
	echo "$i" | jq ".name"
done | fzf \
	--layout=reverse \
	--header="Open session" \
	--header-first \
	--bind="esc:reload(echo)" \
	--bind=esc:abort)"

if [ -z "$session" ]; then
	exit
fi

testSession="$(echo "$session" | sed 's/"//g')"
session="$(echo "$session" | sed 's/\s/\ /g')"

for i in "${sessions[@]}"; do
	test="$(echo -n "$i" | jq -r "select(.name == \"$testSession\") | .name")"
	if [[ "$test" == "$testSession" ]]; then
		sessionJSON="$i"
		break
	fi
done

q() {
	echo "$1" | jq -r "$2"
}

addPanes() {
	local paneCount="$(q "$thisWindowJSON" ".panes[] | .index" | wc -l)"

	local windowIndex="$(q "$sessionJSON" ".windows[] | .index")"

	if ((paneCount > 1)); then
		focusedPane=0

		local count=0

		for i in $(eval echo {0..$((paneCount - 1))}); do
			paneJSON="$(q "$thisWindowJSON" ".panes[$i]")"

			if ((count != 0)); then
				tmuxCommand+=("tmux splitw -t "$session":"$windowIndex" -c \"$(q "$paneJSON" ".path")\"" \;)
			else
				tmuxCommand+=("tmux send-keys -t "$session":"$windowIndex" \"cd \"$(q "$paneJSON" ".path")\"\" Enter" \;)
			fi

			if [[ "$(q "$paneJSON" ".current")" == "true" ]]; then
				focusedPane="$i"
			fi

			if [[ "$(q "$paneJSON" ".command")" != "" ]]; then
				tmuxCommand+=("tmux send-keys -t "$session":"$windowIndex" \" $(q "$paneJSON" ".command")\" Enter" \;)
			fi

			tmuxCommand+=("tmux send-keys -t "$session":"$windowIndex" C-l" \;)

			count=$(((count + 1)))
		done

		tmuxCommand+=("tmux select-pane -t "$session":"$windowIndex"."$focusedPane"" \;)
	else
		paneJSON="$(q "$thisWindowJSON" ".panes[0]")"

		tmuxCommand+=("tmux send-keys -t "$session":"$windowIndex" \"cd \"$(q "$paneJSON" ".path")\"\" Enter" \;)

		tmuxCommand+=("tmux send-keys -t "$session":"$windowIndex" \"\"$(q "$paneJSON" ".command")\"\" Enter" \;)
	fi
}

main() {
	tmuxCommand=("tmux new-session -d -s "$session"" \;)

	local windowCount=$(q "$sessionJSON" ".windows[] | .index" | wc -l)

	# Create all our windows
	if ((windowCount > 1)); then
		focusedWindow="$(q "$sessionJSON" ".windows[] | select(.current == \"true\") | .index")"

		for i in $(eval echo {1..$windowCount}); do
			local thisWindowJSON="$(q "$sessionJSON" ".windows[] | select(.index == \"$1\")")"

			local windowIndex="$(q "$sessionJSON" ".windows[] | .index")"

			tmuxCommand+=("tmux new-window -t "$session" -n "$(q "$thisWindowJSON" ".name")"")

			addPanes "$thisWindowJSON"

			tmuxCommand+=("tmux select-layout -t "$session":"$windowIndex" \""$(q "$thisWindowJSON" ".layout")"\"" \;)
		done

		tmuxCommand+=("tmux select-window -t "$session":"$focusedWindow"" \;)
	else
		local thisWindowJSON="$(q "$sessionJSON" ".windows[0]")"

		addPanes "$thisWindowJSON"

		tmuxCommand+=("tmux select-layout -t "$session" \""$(q "$thisWindowJSON" ".layout")"\"" \;)
	fi

	if [ -z TMUX ]; then
		tmuxCommand+=("tmux attach -t "$session"")
	else
		tmuxCommand+=("tmux switch-client -t "$session"")
	fi

	eval "${tmuxCommand[@]}"
}

main
