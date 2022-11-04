#!/usr/bin/env bash

projects=($(projects dump))

projectName=$(for p in ${projects[@]}; do 
    echo $p | cut -d',' -f1
done | fzf \
--bind="esc:reload(echo)" \
--bind=esc:abort)

if [ ! -z projectName ] && [ ! $projectName = "" ]; then
    for i in ${projects[@]}; do
        project=($(echo $i | sed "s/,/ /g"))
        if [ ${project[0]} = $projectName ]; then
            projectI=$(tmux ls | grep ${project[0]} | wc -l)
            tmux new-session -c "${project[1]}" -s ${project[0]}$projectI -d
            tmux switch-client -t "${project[0]}$projectI"
        fi
    done
fi
