#!/bin/bash

tmux move-window -s "$(tmux display-message -p '#{session_name}:#{window_index}')" -t "$(tmux new -dP)"
