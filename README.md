Project Overview
This project displays a CMATRIX-style animation influenced by daily ritual data. Unlike traditional CMATRIX animations, this version uses real-world data (coin flips, dice rolls, random values, and roulette outcomes) to dynamically alter the visual elements of the animation.

Key Differences from CMATRIX
Dynamic Data Integration: Animation effects are determined by external ritual data (coin flips, dice rolls, random values, and roulette outcomes) rather than random characters alone.
Customizable Streams: The streams’ speed, color, and character set vary based on the data, creating unique animation for each day.
Presentation: Unlike cmatrix, my script has variablilty besides characters, speed, # of lines, bunch, as well as each character in a line being updated dynamically every moment instead of being constant

Submission Details
This project is submitted for the ASM4M course. It is a practical application of programming concepts in C, focusing on using the ncurses library to display matrix-like animations by external data.

How to Run
Ensure ritual-data.dat file is there with VALID data (format it according to mine).
Compile the C program:
gcc -o matrix matrix.c -lncurses
Run the program:
./matrix
