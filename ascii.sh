#!/bin/bash
tput civis
oldstty=$(stty -g)
stty -icanon -echo
trap 'stty "$oldstty"; tput cnorm; exit' INT TERM EXIT
cols=$(tput cols)
rows=$(tput lines)
preset_gradients=("\033[38;5;27m,\033[38;5;33m,\033[38;5;39m,\033[38;5;45m" "\033[38;5;51m,\033[38;5;75m,\033[38;5;81m,\033[38;5;117m" "\033[38;5;33m,\033[38;5;39m,\033[38;5;45m,\033[38;5;51m")
reset="\033[0m"
declare -a drops drop_gradients drop_lengths
for ((i=0; i<cols; i++)); do
  drops[i]=-1
  drop_gradients[i]=""
  drop_lengths[i]=0
done
spark_color="\033[38;5;75m"
spark_mid="\033[38;5;81m"
spark_tail="\033[38;5;45m"
special_color="\033[38;5;45m"
declare -a spark_rows spark_cols spark_lives
declare -a orb_x orb_y orb_dx orb_dy orb_life orb_color
star="✦"
while true; do
  for ((i=0; i<cols; i++)); do
    if [ "${drops[i]}" -ge 0 ]; then
      pos=${drops[i]}
      IFS=',' read -r g0 g1 g2 g3 <<< "${drop_gradients[i]}"
      if (( pos - 3 >= 0 )); then
        tput cup $((pos-3)) $i; echo -ne " "
      fi
      if (( pos - 2 >= 0 )); then
        tput cup $((pos-2)) $i; echo -ne "${g3}$(printf '\\%03o' $(( RANDOM % 94 + 33 )))${reset}"
      fi
      if (( pos - 1 >= 0 )); then
        tput cup $((pos-1)) $i; echo -ne "${g2}$(printf '\\%03o' $(( RANDOM % 94 + 33 )))${reset}"
      fi
      if (( pos < rows )); then
        tput cup $pos $i; echo -ne "${g0}$(printf '\\%03o' $(( RANDOM % 94 + 33 )))${reset}"
      fi
      new_pos=$((pos+1))
      if (( new_pos - drop_lengths[i] >= rows )); then
        for ((j = new_pos - drop_lengths[i]; j < new_pos; j++)); do
          if (( j >= 0 && j < rows )); then
            tput cup $j $i; echo -ne " "
          fi
        done
        drops[i]=-1
        drop_gradients[i]=""
        drop_lengths[i]=0
      else
        drops[i]=$new_pos
      fi
    else
      if (( RANDOM % 40 == 0 )); then
        drops[i]=0
        drop_gradients[i]="${preset_gradients[RANDOM % ${#preset_gradients[@]}]}"
        drop_lengths[i]=$(( RANDOM % 5 + 4 ))
        IFS=',' read -r g0 g1 g2 g3 <<< "${drop_gradients[i]}"
        tput cup 0 $i; echo -ne "${g0}$(printf '\\%03o' $(( RANDOM % 94 + 33 )))${reset}"
      fi
    fi
  done
  if (( RANDOM % 30 == 0 )); then
    spark_rows+=($(( RANDOM % rows )))
    spark_cols+=($(( RANDOM % cols )))
    spark_lives+=(3)
  fi
  for ((s=0; s<${#spark_rows[@]}; s++)); do
    r=${spark_rows[s]}
    c=${spark_cols[s]}
    life=${spark_lives[s]}
    if (( r >= 0 && r < rows && c >= 0 && c < cols )); then
      if (( life == 3 )); then
        col="${spark_color}"
      elif (( life == 2 )); then
        col="${spark_mid}"
      else
        col="${spark_tail}"
      fi
      tput cup $r $c; echo -ne "${col}$(printf '\\%03o' $(( RANDOM % 94 + 33 )))${reset}"
    fi
    spark_lives[s]=$((life-1))
    if (( spark_lives[s] <= 0 )); then
      if (( r >= 0 && r < rows && c >= 0 && c < cols )); then
        tput cup $r $c; echo -ne " "
      fi
      spark_rows[s]=-1
    fi
  done
  new_spark_rows=()
  new_spark_cols=()
  new_spark_lives=()
  for ((s=0; s<${#spark_rows[@]}; s++)); do
    if [ "${spark_rows[s]}" -ge 0 ]; then
      new_spark_rows+=(${spark_rows[s]})
      new_spark_cols+=(${spark_cols[s]})
      new_spark_lives+=(${spark_lives[s]})
    fi
  done
  spark_rows=("${new_spark_rows[@]}")
  spark_cols=("${new_spark_cols[@]}")
  spark_lives=("${new_spark_lives[@]}")
  if (( RANDOM % 100 == 0 )); then
    r=$(( RANDOM % rows ))
    c=$(( RANDOM % cols ))
    tput cup $r $c; echo -ne "${special_color}☽${reset}"
    sleep 0.05
    tput cup $r $c; echo -ne " "
  fi
  if (( RANDOM % 50 == 0 )); then
    orb_x+=( $(( RANDOM % cols )) )
    orb_y+=( $(( (rows / 2) + RANDOM % (rows / 2) )) )
    dx_choice=$(( RANDOM % 3 ))
    if [ $dx_choice -eq 0 ]; then dx=-1; elif [ $dx_choice -eq 1 ]; then dx=0; else dx=1; fi
    orb_dx+=( $dx )
    orb_dy+=( -1 )
    orb_life+=( $(( RANDOM % 10 + 5 )) )
    orb_color+=( "${preset_gradients[RANDOM % ${#preset_gradients[@]}]%%,*}" )
  fi
  for ((o=0; o<${#orb_x[@]}; o++)); do
    old_x=${orb_x[o]}
    old_y=${orb_y[o]}
    if (( old_y >= 0 && old_y < rows && old_x >= 0 && old_x < cols )); then
      tput cup $old_y $old_x; echo -ne " "
    fi
    new_x=$(( old_x + orb_dx[o] ))
    new_y=$(( old_y + orb_dy[o] ))
    orb_x[o]=$new_x
    orb_y[o]=$new_y
    orb_life[o]=$(( orb_life[o] - 1 ))
    if (( new_y >= 0 && new_y < rows && new_x >= 0 && new_x < cols )); then
      tput cup $new_y $new_x; echo -ne "${orb_color[o]}${star}${reset}"
    fi
  done
  new_orb_x=()
  new_orb_y=()
  new_orb_dx=()
  new_orb_dy=()
  new_orb_life=()
  new_orb_color=()
  for ((o=0; o<${#orb_x[@]}; o++)); do
    if (( orb_life[o] > 0 && orb_y[o] >= 0 )); then
      new_orb_x+=( ${orb_x[o]} )
      new_orb_y+=( ${orb_y[o]} )
      new_orb_dx+=( ${orb_dx[o]} )
      new_orb_dy+=( ${orb_dy[o]} )
      new_orb_life+=( ${orb_life[o]} )
      new_orb_color+=( ${orb_color[o]} )
    fi
  done
  orb_x=( "${new_orb_x[@]}" )
  orb_y=( "${new_orb_y[@]}" )
  orb_dx=( "${new_orb_dx[@]}" )
  orb_dy=( "${new_orb_dy[@]}" )
  orb_life=( "${new_orb_life[@]}" )
  orb_color=( "${new_orb_color[@]}" )
  sleep 0.1
  read -rsn1 -t 0 key
  if [[ "$key" == $'\e' ]]; then break; fi
done
stty "$oldstty"
tput cnorm