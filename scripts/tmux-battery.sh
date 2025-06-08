#!/bin/bash

urgentColor="colour9"
_20Color="colour1"
_40Color="colour11"
_60Color="colour3"
_80Color="colour2"

normal="\e[0m"

if [ $(uname) = "Darwin" ]; then
	pmsetOut=($(pmset -g ps | grep -v "Battery Warning" | tail -n1 | awk '{gsub(";", ""); gsub("%", ""); print $3" "$4}'))

	percent=${pmsetOut[0]}

	state=${pmsetOut[1]}
else
	percent=$(cat /sys/class/power_supply/BAT0/capacity)
	state=$(cat /sys/class/power_supply/BAT0/status)
fi

if [ $state = "charging" ] || [ $state = "charged" ]; then
	color=$_80Color
	amountIcon="󰂄"
elif ((percent <= 20)); then
	color=$urgentColor
	amountIcon="󰁻"
elif ((percent <= 40)); then
	color=$_20Color
	amountIcon="󰁽"
elif ((percent <= 60)); then
	color=$_40Color
	amountIcon="󰁾"
elif ((percent <= 80)); then
	color=$_60Color
	amountIcon="󰂁"
elif ((percent <= 100)); then
	color=$_80Color
	amountIcon="󰁹"
fi

printf "#[fg=$color, bg=colour235] $amountIcon ${percent}%% #[fg=colour0, bg=$color]"
