#!/bin/bash
tput civis
oldstty=$(stty -g)
stty -icanon -echo
trap 'stty "$oldstty"; tput cnorm; exit' INT TERM EXIT

cols=$(tput cols)
rows=$(tput lines)
spacing=2
numcols=$(( (cols + spacing - 1) / spacing ))

# Preset gradients: each string contains comma-separated ANSI codes for:
# head, first tail, second tail, third tail.
preset_gradients=(
  "\033[38;5;15m,\033[38;5;240m,\033[38;5;236m,\033[38;5;232m"
  "\033[38;5;15m,\033[38;5;237m,\033[38;5;233m,\033[38;5;232m"
  "\033[38;5;15m,\033[38;5;245m,\033[38;5;236m,\033[38;5;232m"
)
reset="\033[0m"
bold="\033[1m"

# Arrays for each drop column:
declare -a drops drop_lengths spaces
for ((i=0; i<numcols; i++)); do
  drops[i]=-1
  drop_lengths[i]=$(( RANDOM % 5 + 4 ))
  spaces[i]=$(( RANDOM % rows + 1 ))
done

# Spark colors and special symbol color.
spark_color="\033[38;5;15m"
spark_mid="\033[38;5;236m"
spark_tail="\033[38;5;232m"
special_color="\033[38;5;232m"

declare -a spark_rows spark_cols spark_lives
declare -a orb_x orb_y orb_dy orb_life orb_color
star="✦"

while true; do
  # Process each drop column (spaced out horizontally)
  for ((i=0; i<numcols; i++)); do
    col_pos=$(( i * spacing ))
    if (( drops[i] >= 0 )); then
      progress=${drops[i]}
      head_row=$(( progress % rows ))
      # Choose a random gradient each update:
      IFS=',' read -r g0 g1 g2 g3 <<< "${preset_gradients[RANDOM % ${#preset_gradients[@]}]}"
      
      # Draw tail characters at offsets 1..drop_lengths[i]
      for ((offset=1; offset<=drop_lengths[i]; offset++)); do
        if (( progress >= offset )); then
          tail_row=$(( (progress - offset + rows) % rows ))
          # Use different shade based on offset.
          if (( offset == 1 )); then
            tput cup $tail_row $col_pos; echo -ne "${g2}${bold}$(printf '\\%03o' $(( RANDOM % 94 + 33 )))${reset}"
          else
            tput cup $tail_row $col_pos; echo -ne "${g3}${bold}$(printf '\\%03o' $(( RANDOM % 94 + 33 )))${reset}"
          fi
        fi
      done

      # Clear cell just beyond the tail.
      if (( progress >= drop_lengths[i] )); then
        clear_row=$(( (progress - drop_lengths[i] + rows) % rows ))
        tput cup $clear_row $col_pos; echo -ne " "
      fi

      # Draw the head in the head color.
      tput cup $head_row $col_pos; echo -ne "${g0}${bold}$(printf '\\%03o' $(( RANDOM % 94 + 33 )))${reset}"
      
      # Increment progress.
      drops[i]=$(( progress + 1 ))
      if (( drops[i] >= rows + drop_lengths[i] )); then
        drops[i]=-1
        spaces[i]=$(( RANDOM % rows + 1 ))
      fi
    else
      # No active drop; count down before spawning a new one.
      if (( spaces[i] > 0 )); then
        spaces[i]=$(( spaces[i] - 1 ))
      else
        drops[i]=0
        drop_lengths[i]=$(( RANDOM % 5 + 4 ))
        IFS=',' read -r g0 g1 g2 g3 <<< "${preset_gradients[RANDOM % ${#preset_gradients[@]}]}"
        tput cup 0 $col_pos; echo -ne "${g0}${bold}$(printf '\\%03o' $(( RANDOM % 94 + 33 )))${reset}"
        spaces[i]=$(( RANDOM % rows + 1 ))
      fi
    fi
  done

  # Spawn sparks in random positions (with random color variation)
  if (( RANDOM % 50 == 0 )); then
    spark_rows+=($(( RANDOM % rows )))
    spark_cols+=($(( (RANDOM % numcols) * spacing )))
    spark_lives+=(3)
  fi

  for ((s=0; s<${#spark_rows[@]}; s++)); do
    r=${spark_rows[s]}
    c=${spark_cols[s]}
    life=${spark_lives[s]}
    if (( r >= 0 && r < rows && c >= 0 && c < cols )); then
      # Choose a random color on each update.
      case $(( RANDOM % 3 )) in
        0) col="${spark_color}${bold}" ;;
        1) col="${spark_mid}${bold}" ;;
        2) col="${spark_tail}${bold}" ;;
      esac
      tput cup $r $c; echo -ne "${col}$(printf '\\%03o' $(( RANDOM % 94 + 33 )))${reset}"
    fi
    spark_lives[s]=$(( life - 1 ))
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

  # Spawn a special symbol occasionally.
  if (( RANDOM % 100 == 0 )); then
    r=$(( RANDOM % rows ))
    c=$(( (RANDOM % numcols) * spacing ))
    tput cup $r $c; echo -ne "${special_color}${bold}☽${reset}"
    sleep 0.001
    tput cup $r $c; echo -ne " "
  fi

  # Spawn orbs that only move downward.
  if (( RANDOM % 50 == 0 )); then
    orb_x+=( $(( (RANDOM % numcols) * spacing )) )
    orb_y+=( $(( (rows / 2) + RANDOM % (rows / 2) )) )
    orb_dy+=( -1 )
    orb_life+=( $(( RANDOM % 10 + 5 )) )
    orb_color+=( "$(echo "${preset_gradients[RANDOM % ${#preset_gradients[@]}]}" | cut -d',' -f4)" )
  fi

  for ((o=0; o<${#orb_x[@]}; o++)); do
    old_x=${orb_x[o]}
    old_y=${orb_y[o]}
    if (( old_y >= 0 && old_y < rows && old_x >= 0 && old_x < cols )); then
      tput cup $old_y $old_x; echo -ne " "
    fi
    new_y=$(( old_y + orb_dy[o] ))
    orb_y[o]=$new_y
    orb_life[o]=$(( orb_life[o] - 1 ))
    if (( new_y >= 0 && new_y < rows && old_x >= 0 && old_x < cols )); then
      tput cup $new_y $old_x; echo -ne "${orb_color[o]}${bold}${star}${reset}"
    fi
  done

  new_orb_x=()
  new_orb_y=()
  new_orb_dy=()
  new_orb_life=()
  new_orb_color=()
  for ((o=0; o<${#orb_x[@]}; o++)); do
    if (( orb_life[o] > 0 && orb_y[o] >= 0 )); then
      new_orb_x+=( ${orb_x[o]} )
      new_orb_y+=( ${orb_y[o]} )
      new_orb_dy+=( ${orb_dy[o]} )
      new_orb_life+=( ${orb_life[o]} )
      new_orb_color+=( ${orb_color[o]} )
    fi
  done
  orb_x=( "${new_orb_x[@]}" )
  orb_y=( "${new_orb_y[@]}" )
  orb_dy=( "${new_orb_dy[@]}" )
  orb_life=( "${new_orb_life[@]}" )
  orb_color=( "${new_orb_color[@]}" )

  sleep 0.001
  read -rsn1 -t 0 key
  if [[ "$key" == $'\e' ]]; then break; fi
done

stty "$oldstty"
tput cnorm