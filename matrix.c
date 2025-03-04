#include <locale.h>               // For setlocale and LC_ALL
#define _XOPEN_SOURCE_EXTENDED    // Enable wide-character support in ncurses
#include <ncurses.h>              // For ncurses functions and types
#include <stdlib.h>               // For malloc, free, rand, srand
#include <time.h>                 // For time
#include <unistd.h>               // For usleep
#include <string.h>               // For string functions
#include <stdbool.h>              // For bool type
#include <ctype.h>                // For toupper, isspace
#include <wchar.h>                // For wide characters
#include <wctype.h>               // For wide character types

#define DATA_FILE "ritual-data.dat"
#define DELAY 20000               // Delay
#define STREAM_DENSITY 75         // Percentage chance of a column having a stream

typedef struct {
    int day_number;
    int coin;
    int dice;
    int random_value;
    char roulette[32];
} DayData;

typedef struct {
    bool active;
    int head_y;
    int length;
    int speed;
    int frame;
    int delay;
} Stream;

static int load_ritual_data(const char *filename, DayData *days, int max_days) {
    FILE *fp = fopen(filename, "r");
    if (!fp) return 0;
    int day_count = 0, current_day = 0;
    char line[256];
    while (fgets(line, sizeof(line), fp) && day_count < max_days) {
        char *p = line;
        while (isspace((unsigned char)*p)) p++;
        if (*p == '\0' || (*p == '#' && strncasecmp(p, "# Day", 5) != 0))
            continue;
        if (strncasecmp(p, "# Day", 5) == 0) {
            sscanf(p, "# Day %d", &current_day);
            continue;
        }
        char key[32], value[32];
        if (sscanf(p, "%31[^=]=%31s", key, value) == 2) {
            for (char *c = key; *c; c++) *c = toupper((unsigned char)*c);
            if (strcmp(key, "COIN") == 0) days[day_count].coin = atoi(value);
            else if (strcmp(key, "DICE") == 0) days[day_count].dice = atoi(value);
            else if (strcmp(key, "RANDOM") == 0) days[day_count].random_value = atoi(value);
            else if (strcmp(key, "ROULETTE") == 0) {
                strncpy(days[day_count].roulette, value, sizeof(days[day_count].roulette)-1);
                days[day_count].roulette[sizeof(days[day_count].roulette)-1] = '\0';
            }
        }
        if (strncmp(key, "ROULETTE", 8) == 0) {
            days[day_count].day_number = current_day;
            day_count++;
        }
    }
    fclose(fp);
    return day_count;
}

// Creates clusters of streams with gaps
static void initialize_streams(Stream *streams, int max_x, int tail_len) {
    bool creating_cluster = false;
    int cluster_size = 0;
    int gap_size = 0;
    
    for (int x = 0; x < max_x; x++) {
        streams[x].active = false;
        streams[x].delay = rand() % 30; // Reduced max delay
        
        if (!creating_cluster) {
            // Start a new cluster with probability based on position
            if (rand() % 100 < 30) {
                creating_cluster = true;
                cluster_size = 5 + rand() % 10; // Random cluster
            }
        }
        
        if (creating_cluster) {
            // Higher probability of being active within a cluster
            streams[x].active = (rand() % 100 < STREAM_DENSITY);
            cluster_size--;
            if (cluster_size <= 0) {
                creating_cluster = false;
                gap_size = 2 + rand() % 3; // Small gap
            }
        } else {
            streams[x].active = false; // Force a gap
            gap_size--;
        }
        
        if (streams[x].active) {
            streams[x].head_y = -(rand() % 15); // Start closer to top
            streams[x].length = tail_len + (rand() % 5); // Slight variation in tail length
            streams[x].speed = 2 + rand() % 3; // Increased speed range
            streams[x].frame = 0;
        }
    }
}

int main(void) {
    DayData days[64];
    int num_days = load_ritual_data(DATA_FILE, days, 64);
    if (num_days == 0) {
        printf("Error: Could not load ritual data from %s\n", DATA_FILE);
        return 1;
    }
    srand(time(NULL));
    int pick = rand() % num_days;
    DayData chosen = days[pick];

    int tail_len = chosen.dice;
    srand(chosen.random_value);
    short tail_color = COLOR_GREEN;
    if (strcasecmp(chosen.roulette, "red") == 0) tail_color = COLOR_RED;
    else if (strcasecmp(chosen.roulette, "yellow") == 0) tail_color = COLOR_YELLOW;

    const wchar_t *ascii_set = L"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789@#$%^&*()-_=+";
    const wchar_t *japanese_set = L"ｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎﾏﾐﾑﾒﾓ";

    wchar_t combined_set[1024] = L"";
    if (strcasecmp(chosen.roulette, "black") == 0) {
        wcscat(combined_set, japanese_set);
        wcscat(combined_set, japanese_set);
        wcscat(combined_set, ascii_set);
    } else if (strcasecmp(chosen.roulette, "red") == 0) {
        wcscat(combined_set, ascii_set);
        wcscat(combined_set, ascii_set);
        wcscat(combined_set, japanese_set);
    } else if (strcasecmp(chosen.roulette, "yellow") == 0) {
        wcscat(combined_set, ascii_set);
        wcscat(combined_set, japanese_set);
    } else {
        wcscat(combined_set, ascii_set);
        wcscat(combined_set, japanese_set);
    }

    setlocale(LC_ALL, "");
    initscr();
    noecho();
    curs_set(FALSE);
    nodelay(stdscr, TRUE);
    if (has_colors()) {
        start_color();
        if (use_default_colors() == OK) {
            init_pair(1, tail_color, -1);
            init_pair(2, COLOR_WHITE, -1);
        } else {
            init_pair(1, tail_color, COLOR_BLACK);
            init_pair(2, COLOR_WHITE, COLOR_BLACK);
        }
    }

    int max_y, max_x;
    getmaxyx(stdscr, max_y, max_x);
    Stream *streams = malloc(sizeof(Stream) * max_x);
    if (!streams) {
        endwin();
        return 1;
    }

    initialize_streams(streams, max_x, tail_len);

    int iteration = 0;
    
    while (1) {
        erase();
        iteration++;
        
        if (iteration % 100 == 0) {
            for (int x = 0; x < max_x; x++) {
                if (!streams[x].active && rand() % 100 < 20) {
                    if (rand() % 100 < STREAM_DENSITY) {
                        streams[x].active = true;
                        streams[x].head_y = -(rand() % 10);
                        streams[x].length = tail_len + (rand() % 5);
                        streams[x].speed = 2 + rand() % 3;
                        streams[x].frame = 0;
                    }
                }
            }
        }
            
        for (int x = 0; x < max_x; x++) {
            Stream *s = &streams[x];
            if (!s->active) {
                if (s->delay > 0) { s->delay--; continue; }
                s->active = true;
                s->head_y = -(rand() % 10);
                s->length = tail_len + (rand() % 5);
                s->speed = 2 + rand() % 3;
                s->frame = 0;
            }
            
            // Update position more frequently
            s->frame++;
            if (s->frame >= s->speed) { 
                s->frame = 0;
                s->head_y++;
                
                // Chance to change speed
                if (rand() % 50 == 0) {
                    s->speed = 1 + rand() % 4;
                }
            }
            
            int tail_start = s->head_y - s->length + 1;
            for (int row = tail_start; row <= s->head_y; row++) {
                if (row < 0 || row >= max_y) continue;
                int set_len = wcslen(combined_set);
                
                // Change characters more frequently
                wchar_t random_char = combined_set[rand() % set_len];
                
                cchar_t cc;
                if (row == s->head_y) {
                    attr_t attrs = (chosen.coin == 1) ? A_BOLD : A_NORMAL;
                    setcchar(&cc, &random_char, attrs, 2, NULL);
                } else {
                    int distance_from_head = s->head_y - row;
                    if (distance_from_head < s->length / 3) {
                        setcchar(&cc, &random_char, A_NORMAL, 1, NULL);
                    } else {
                        setcchar(&cc, &random_char, A_DIM, 1, NULL);
                    }
                }
                mvadd_wch(row, x, &cc);
            }
            
            if (s->head_y - s->length + 1 >= max_y) {
                s->active = false;
                s->delay = rand() % 20; // Shorter delay
                
                // Reposition some streams to maintain grouping
                if (x > 0 && x < max_x - 1) {
                    if ((streams[x-1].active || streams[x+1].active) && rand() % 100 < 70) {
                        s->delay = rand() % 5; // Very short delay
                    }
                }
            }
        }
        
        refresh();
        usleep(DELAY);
        if (getch() != ERR) break;
    }

    free(streams);
    endwin();
    return 0;
}