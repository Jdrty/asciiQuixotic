#!/bin/bash
tput civis
oldstty=$(stty -g)
stty -icanon -echo
trap 'stty "$oldstty"; tput cnorm; exit' INT TERM EXIT

# Green-themed colors (Matrix style)
colors=("\033[38;5;22m" "\033[38;5;28m" "\033[38;5;34m" "\033[38;5;40m" "\033[38;5;46m")
reset="\033[0m"
cols=$(tput cols)

while true; do
  line=""
  for ((j=0; j<cols; j++)); do
    color=${colors[RANDOM % ${#colors[@]}]}
    rand=$(( RANDOM % 94 + 33 ))
    char=$(printf "\\$(printf '%03o' "$rand")")
    line+="${color}${char}${reset}"
  done
  echo -e "$line"
  read -rsn1 -t 0 key
  [[ "$key" == $'\e' ]] && break
  sleep 0.1
done

stty "$oldstty"
tput cnorm