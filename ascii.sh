# Hide the cursor
tput civis

# Ensure the cursor is restored
trap "tput cnorm; exit" INT TERM EXIT

# Loop indefinitely to update the screen.
while true; do
  clear
  rows=$(tput lines)
  cols=$(tput cols)
  for ((i = 0; i < rows; i++)); do
    line=""
    for ((j = 0; j < cols; j++)); do
      # Generate a random ASCII code between 33 (!) and 126 (~)
      rand=$(( RANDOM % 94 + 33 ))
      # Append the corresponding character to the line.
      line+=$(printf "\\$(printf '%03o' "$rand")")
    done
    echo "$line"
  done
  # Adjust the sleep duration to control the refresh rate.
  sleep 0.1
done
