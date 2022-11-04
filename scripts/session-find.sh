#!/usr/bin/env bash
sessions=($(tmux ls | grep "^[a-zA-Z]" | cut -d":" -f1))

choice=$(for i in ${sessions[@]}; do
    echo $i
done | fzf \
--header="Find session" \
--header-first \
--layout=reverse \
--bind "esc:reload(echo)" \
--bind esc:abort)

if [ ! $choice = "" ]; then
    tmux switch-client -t $choice
fi
