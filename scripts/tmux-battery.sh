#!/bin/bash

urgentColor="#[bg=red]"
_20Color="#[fg=red]"
_40Color="#[fg=yellow]"
_60Color="#[fg=green,bright]"
_80Color="#[fg=cyan,bright]"

normal="\e[0m"
percent=$(cat /sys/class/power_supply/BAT0/capacity)

state=$(cat /sys/class/power_supply/BAT0/status)

if ((percent <= 20)); then
    color=$urgentColor
    amountIcon=""
elif ((percent <= 40)); then
    color=$_20Color
    amountIcon=""
elif ((percent <= 60)); then
    color=$_40Color
    amountIcon=""
elif ((percent <= 80)); then
    color=$_60Color
    amountIcon=""
elif ((percent <= 100)); then
    color=$_80Color
    amountIcon=""
elif [[ $state == "Charging" ]]; then
    amountIcon=""
fi

printf "$amountIcon: $color$percent"
