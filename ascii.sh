#!/bin/bash

# Data file path
DATA_FILE="ritual-data.dat"

# Function to read current day's data
get_day_data() {
    local day=$1
    local start_pattern="# Day $day"
    local end_pattern="# Day $((day+1))"
    
    COIN_DATA=$(sed -n "/$start_pattern/,/$end_pattern/p" "$DATA_FILE" | grep "^COIN" | cut -d'=' -f2)
    DICE_DATA=$(sed -n "/$start_pattern/,/$end_pattern/p" "$DATA_FILE" | grep "^DICE" | cut -d'=' -f2)
    RANDOM_DATA=$(sed -n "/$start_pattern/,/$end_pattern/p" "$DATA_FILE" | grep "^RANDOM" | cut -d'=' -f2)
    ROULETTE_DATA=$(sed -n "/$start_pattern/,/$end_pattern/p" "$DATA_FILE" | grep "^ROULETTE" | cut -d'=' -f2)
}

# Initialize display settings
tput civis
oldstty=$(stty -g)
stty -icanon -echo
trap 'stty "$oldstty"; tput cnorm; exit' INT TERM EXIT
cols=$(tput cols)
rows=$(tput lines)

# Define color schemes based on roulette outcomes
scheme_1=("\033[38;5;27m,\033[38;5;33m,\033[38;5;39m,\033[38;5;45m")
scheme_2=("\033[38;5;51m,\033[38;5;75m,\033[38;5;81m,\033[38;5;117m")
scheme_3=("\033[38;5;226m,\033[38;5;220m,\033[38;5;214m,\033[38;5;208m") # Yellow scheme

# Initialize arrays for animation
declare -a drops drop_gradients drop_lengths
for ((i=0; i<cols; i++)); do
    drops[i]=-1
    drop_gradients[i]=""
    drop_lengths[i]=0
done

# Animation variables
current_day=1
data_index=0
current_scheme=0
special_symbols=("✦" "✧" "★" "☆" "✯")
reset="\033[0m"

# Main animation loop
while true; do
    # Read current day's data
    get_day_data $current_day
    
    # Convert comma-separated strings to arrays
    IFS=',' read -ra COIN_ARRAY <<< "$COIN_DATA"
    IFS=',' read -ra DICE_ARRAY <<< "$DICE_DATA"
    IFS=',' read -ra RANDOM_ARRAY <<< "$RANDOM_DATA"
    IFS=',' read -ra ROULETTE_ARRAY <<< "$ROULETTE_DATA"
    
    # Use current data point
    current_coin=${COIN_ARRAY[$data_index]}
    current_dice=${DICE_ARRAY[$data_index]}
    current_random=${RANDOM_ARRAY[$data_index]}
    current_roulette=${ROULETTE_ARRAY[$data_index]}
    
    # Apply data effects
    
    # Coin flip affects color scheme
    if [ "$current_coin" -eq 1 ]; then
        preset_gradients=("${scheme_1[@]}")
    else
        preset_gradients=("${scheme_2[@]}")
    fi
    
    # Dice roll affects drop length
    base_drop_length=$((current_dice))
    
    # Random number affects spawn rate
    spawn_rate=$((current_random % 50 + 10))
    
    # Roulette affects special effects
    case "$current_roulette" in
        "yellow")
            preset_gradients=("${scheme_3[@]}")
            special_rate=20
            ;;
        "black")
            special_rate=100
            ;;
        "red")
            special_rate=50
            ;;
    esac
    
    # Matrix-style rain effect
    for ((i=0; i<cols; i++)); do
        if [ "${drops[i]}" -ge 0 ]; then
            pos=${drops[i]}
            IFS=',' read -r g0 g1 g2 g3 <<< "${drop_gradients[i]}"
            
            # Draw falling characters
            for ((j=0; j<4; j++)); do
                if (( pos-j >= 0 && pos-j < rows )); then
                    tput cup $((pos-j)) $i
                    eval "echo -ne \"\${g$j}$(printf '\\%03o' $(( RANDOM % 94 + 33 )))${reset}\""
                fi
            done
            
            # Clear old position
            if (( pos - 4 >= 0 )); then
                tput cup $((pos-4)) $i
                echo -ne " "
            fi
            
            # Update position
            drops[i]=$((pos + 1))
            
            # Check if drop should end
            if (( drops[i] >= rows + 4 )); then
                drops[i]=-1
            fi
        elif (( RANDOM % spawn_rate == 0 )); then
            # Start new drop
            drops[i]=0
            drop_gradients[i]="${preset_gradients[RANDOM % ${#preset_gradients[@]}]}"
            drop_lengths[i]=$((base_drop_length))
        fi
    done
    
    # Special effects based on current_random
    if (( RANDOM % special_rate == 0 )); then
        x=$((RANDOM % cols))
        y=$((RANDOM % rows))
        symbol=${special_symbols[RANDOM % ${#special_symbols[@]}]}
        tput cup $y $x
        echo -ne "${preset_gradients[0]%%,*}$symbol${reset}"
    fi
    
    # Update data indices
    data_index=$((data_index + 1))
    if [ $data_index -ge 8 ]; then  # Assuming 8 data points per day
        data_index=0
        current_day=$((current_day + 1))
        if [ $current_day -gt 7 ]; then
            current_day=1
        fi
    fi
    
    sleep 0.1
    
    # Check for escape key
    read -rsn1 -t 0 key
    if [[ "$key" == $'\e' ]]; then 
        break
    fi
done

# Cleanup
stty "$oldstty"
tput cnorm