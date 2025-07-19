GCC := gcc
BUILD_DIR := bin
SHELL := bash

clean:
	rm -r "$(BUILD_DIR)"
	
%.o: %.c
	mkdir -p "$(BUILD_DIR)"
	gcc -c -o "$(BUILD_DIR)/$@" "$<"

build: main.o
	gcc -o "$(BUILD_DIR)/main" "$(BUILD_DIR)/main.o"

.PHONY: build