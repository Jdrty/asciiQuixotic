#include <ncurses.h>
#include <stdlib.h>
#include <time.h>
#include <unistd.h>
#include <stdbool.h>

#define DELAY 50000

// Each column will be a "stream" with these properties
typedef struct {
    bool active;  
    int head_y;     
    int length;  
    int speed;      
    int frame;      
    int delay;    
} Stream;

// Pick a random character from the CHAR_SET
static char random_char(void) {
    static const char CHAR_SET[] =
        "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789@#$%^&*()-_=+";
    int size = (int)(sizeof(CHAR_SET) - 1);
    return CHAR_SET[rand() % size];
}

int main(void) {
    initscr();
    noecho();
    curs_set(FALSE);
    nodelay(stdscr, TRUE);

    // Use terminal's default background if possible
    if (has_colors()) {
        start_color();
        if (use_default_colors() == OK) {
            init_pair(1, COLOR_GREEN, -1); // Tail in green on default background
            init_pair(2, COLOR_WHITE, -1); // Head in white on default background
        } else {
            // Fallback to black background if default colors aren't supported
            init_pair(1, COLOR_GREEN, COLOR_BLACK);
            init_pair(2, COLOR_WHITE, COLOR_BLACK);
        }
    }

    srand((unsigned)time(NULL));

    int max_y, max_x;
    getmaxyx(stdscr, max_y, max_x);

    // Create a "stream" for each column
    Stream *streams = malloc(sizeof(Stream) * max_x);
    if (!streams) {
        endwin();
        return 1;
    }

    // Initialize each column
    for (int x = 0; x < max_x; x++) {
        streams[x].active = false;
        streams[x].delay = rand() % 50; 
    }

    while (1) {
        erase();  // Clear screen each frame

        // For each column
        for (int x = 0; x < max_x; x++) {
            Stream *s = &streams[x];

            if (!s->active) {
                if (s->delay > 0) {
                    s->delay--;
                    continue;
                } else {
                    // Activate a new falling column
                    s->active = true;
                    s->head_y = -(rand() % max_y);       // Start above
                    s->length = 3 + rand() % 10;         // Tail length between 3..12
                    s->speed = 1 + rand() % 3;           // Speed factor
                    s->frame = 0;
                }
            }

            // If active, check to move down
            s->frame++;
            if (s->frame >= s->speed) {
                s->frame = 0;
                s->head_y++;
            }

            int tail_start = s->head_y - s->length + 1;
            for (int row = tail_start; row <= s->head_y; row++) {
                if (row < 0 || row >= max_y) {
                    // Skip rows off-screen
                    continue;
                }

                // If it's the head row
                if (row == s->head_y) {
                    attron(COLOR_PAIR(2) | A_BOLD);
                    mvaddch(row, x, random_char());
                    attroff(COLOR_PAIR(2) | A_BOLD);
                } else {
                    // Tail rows
                    attron(COLOR_PAIR(1) | A_DIM);
                    mvaddch(row, x, random_char());
                    attroff(COLOR_PAIR(1) | A_DIM);
                }
            }

            // Reset once time
            if (s->head_y - s->length > max_y) {
                s->active = false;
                s->delay = rand() % 50; // Wait random frames
            }
        }

        refresh();
        usleep(DELAY);

        // Break on any key press
        if (getch() != ERR) {
            break;
        }
    }

    free(streams);
    endwin();
    return 0;
}