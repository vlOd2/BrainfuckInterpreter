#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <stdbool.h>
#include <string.h>
#include <errno.h>
#include <signal.h>
#include <time.h>

#define DATA_ARRAY_SIZE 30000

static uint8_t* data;
static uint8_t* program;
static int dataPtr = 0;
static int programPtr = 0;
static long programSize = 0;

static void terminate(int code) {
    free(program);
    free(data);
    exit(code);
}

static inline void handleNextCell() {
    dataPtr++;
    if (dataPtr >= DATA_ARRAY_SIZE) {
        fprintf(stderr, "\nerror: data pointer out of bounds\n");
        terminate(1);
    }
}

static inline void handlePrevCell() {
    dataPtr--;
    if (dataPtr < 0) {
        fprintf(stderr, "\nerror: data pointer out of bounds\n");
        terminate(1);
    }
}

static inline void handleIncrCell() {
    data[dataPtr]++;
}

static inline void handleDecrCell() {
    data[dataPtr]--;
}

static inline void handleOutputCell() {
    putc(data[dataPtr], stdout);
}

static inline void handleReadCell() {
    char c = getchar();
    if (c == EOF) {
        return;
    }
    data[dataPtr] = c;
}

static inline void handleFwdJump() {
    if (data[dataPtr] != 0) {
        return;
    }
    programPtr--;
    int loop = 1;
    while (loop > 0) {
        if (programPtr + 1 >= programSize) {
            fprintf(stderr, "\nerror: unmatched [\n");
            terminate(1);
        }
        char c = program[++programPtr];
        if (c == '[') loop++;
        if (c == ']') loop--;
    }
}

static inline void handleBwdJump() {
    if (data[dataPtr] == 0) {
        return;
    }
    programPtr--;
    int loop = 1;
    while (loop > 0) {
        if (programPtr - 1 < 0) {
            fprintf(stderr, "\nerror: unmatched ]\n");
            terminate(1);
        }
        char c = program[--programPtr];
        if (c == ']') loop++;
        if (c == '[') loop--;
    }
}

static inline void opcodeHandler(char op) {
    switch (op) {
        case '>':
            handleNextCell();
            break;

        case '<':
            handlePrevCell();
            break;

        case '+':
            handleIncrCell();
            break;
            
        case '-':
            handleDecrCell();
            break;
            
        case '.':
            handleOutputCell();
            break;

        case ',':
            handleReadCell();
            break;

        case '[':
            handleFwdJump();
            break;

        case ']':
            handleBwdJump();
            break;

        default:
            // Ignore invalid opcodes
            break;
    }
}

static bool loadProgram(const char* fileName) {
    FILE* file = fopen(fileName, "r");
    if (!file) {
        return false;
    }

    fseek(file, 0, SEEK_END);
    long fileSize = ftell(file);
    rewind(file);

    programSize = fileSize;
    program = malloc(fileSize);
    memset(program, 0, fileSize);

    fread(program, 1, fileSize, file);
    fclose(file);
    fprintf(stderr, "loaded program, size: %d\n", fileSize);

    return true;
}

static void interruptHandler(int signum) {
    fprintf(stderr, "\naborted\n");
    terminate(0);
}

int main(int argc, char** argv) {
    if (argc < 2) {
        fprintf(stderr, "usage: %s <file>\n", argv[0]);
        return 1;
    }
    
    if (!loadProgram(argv[1])) {
        fprintf(stderr, "error: could not open %s\n", argv[1]);
        return 1;
    }
    
    data = malloc(DATA_ARRAY_SIZE);
    memset(data, 0, DATA_ARRAY_SIZE);
    signal(SIGINT, interruptHandler);
    fprintf(stderr, "running, press ctrl+c to abort, press ctrl+d EOF\n");
    
    clock_t startTime = clock();
    while (programPtr < programSize) {
        char op = program[programPtr];
        programPtr++;
        opcodeHandler(op);
    }

    double execTime = (double)(clock() - startTime) / CLOCKS_PER_SEC;
    fprintf(stderr, "\ndone, took: %f\n", execTime);
    terminate(0);

    return 0;
}