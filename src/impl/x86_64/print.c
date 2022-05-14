#include "print.h"

const static size_t NUM_COLS = 80;
const static size_t NUM_ROWS = 25;

struct Char
{ // ascii and 8bit color

    uint8_t character;
    uint8_t color;
};

struct Char *buffer = (struct Char *)0xb8000;
size_t col = 0;
size_t row = 0;
uint8_t color = PRINT_COLOR_WHITE | PRINT_COLOR_BLACK << 4;

// function def

void clear_row(size_t row)
{ // print all empty characters
    struct Char empty = (struct Char){
        character : ' ',
        color : color,
    };

    for (size_t col = 0; col < NUM_COLS; col++)
    {
        buffer[col + NUM_COLS * row] = empty;
    }
}

void print_clear()
{
    for (size_t i = 0; i < NUM_ROWS; i++)
    {
        clear_row(i);
    }
}

// actual printing

void print_newline()
{
    col = 0;

    if (row < NUM_ROWS - 1) // no last row
    {
        row++;
        return;
    }

    for (size_t row = 1; row < NUM_ROWS; row++)
    {
        for (size_t col = 0; col < NUM_COLS; col++)
        {
            struct Char character = buffer[col + NUM_COLS * row];
            buffer[col + NUM_COLS * (row - 1)] = character; // mov char up by one row
        }
    }

    clear_row(NUM_COLS - 1); // clear row if row is the last row
}

void print_char(char character)
{
    if (character == '\n')
    {
        print_newline();
        return;
    }

    if (col > NUM_COLS) // col>80
    {
        print_newline();
    }
    // create new char into buffer
    buffer[col + NUM_COLS * row] = (struct Char){

        character : (uint8_t)character,
        color : color,
    };

    col++;
}

void print_str(char *str)
{
    for (size_t i = 0; 1; i++)
    {
        char character = (uint8_t)str[i];

        if (character == '\0')
        {
            return;
        }

        print_char(character);
    }
}

void print_set_color(uint8_t foreground, uint8_t background)
{
    color = foreground + (background << 4); // 4+4 bits
}
© 2022 GitHub, Inc.
