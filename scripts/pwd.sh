if [[ "$1" == "$HOME" ]]; then
	echo "~"

	exit
fi

dirs=($(echo "$1" | sed "s#$HOME#~#" | sed 's/\//\n/g'))

count=0
for i in "${dirs[@]}"; do
	if [[ "$i" =~ "~" ]]; then
		echo -n "~"
		let count++
		continue
	fi

	if ((count == ${#dirs[@]} - 1)); then
		echo -n "/${i}"

		exit
	else
		if ((${#i} > 3)); then
			echo -n "/${i:0:3}…"
		else
			echo -n "/${i}"
		fi

		let count++
	fi
done
tmux refresh -S
