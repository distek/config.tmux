#!/bin/bash

unset TMUX
tmux -S "/tmp/tmux-vim_${1}" -f $HOME/.config/tmux/minimal.conf new -d
exit
