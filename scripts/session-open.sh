#!/usr/bin/env bash

sessionsDir=~/.local/share/nvim/sessions

if ! cd "$sessionsDir"; then
	echo "Could not cd into $sessionsDir"
	exit 1
fi

projects=($(for i in $(ls -1 --sort=time); do
	printf "%s:%s\n" "$i" $(grep -i '" name:' $i | sed 's/"\ name://')
done))

projectName=$(for p in ${projects[@]}; do
	echo $p | cut -d':' -f2
done | fzf \
	--layout=reverse \
	--header="Open session" \
	--header-first \
	--bind="esc:reload(echo)" \
	--bind=esc:abort)

if [ ! -z projectName ] && [ ! $projectName = "" ]; then
	for i in ${projects[@]}; do
		project=($(echo $i | sed "s/:/ /g"))

		if [ ${project[1]} = $projectName ]; then
			currentSessions=($(tmux ls | grep ${project[1]}))
			if [ ${#currentSessions[@]} != 0 ]; then
				tmux switch-client -t "$(echo ${currentSessions[0]})"
				exit
			fi

			projectDir=$(grep -i '" cwd:' ${project[0]} | sed 's/"\ cwd://')

			tmux new-session -c "$projectDir" -s ${project[1]} -d

			tmux send-keys -t "${project[1]}" " vim -c \"SessionLoad ${project[1]}\"" "Enter"

			tmux switch-client -t "${project[1]}"
		fi
	done
fi
