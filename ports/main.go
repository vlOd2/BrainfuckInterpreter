package main

import (
	"bufio"
	"fmt"
	"os"
	"os/signal"
	"time"
)

const DATA_ARRAY_SIZE = 30000
var data []byte
var program []byte
var dataPtr int = 0
var programPtr int = 0
var inputReader *bufio.Reader = bufio.NewReader(os.Stdin)

func terminate(code int) {
	data = nil
	program = nil
	os.Exit(code)
}

func handleNextCell() {
	dataPtr++;
	if dataPtr >= DATA_ARRAY_SIZE {
		fmt.Fprintf(os.Stderr, "\nerror: data pointer out of bounds\n");
		terminate(1);
	}
}

func handlePrevCell() {
	dataPtr--;
	if dataPtr < 0 {
		fmt.Fprintf(os.Stderr, "\nerror: data pointer out of bounds\n");
		terminate(1);
	}
}

func handleIncrCell() {
	data[dataPtr]++;
}

func handleDecrCell() {
	data[dataPtr]--;
}

func handleOutputCell() {
	fmt.Print(string(data[dataPtr]));
}

func handleReadCell() {
	c, err := inputReader.ReadByte()
	if (err != nil) {
		return;
	}
	data[dataPtr] = c;
}

func handleFwdJump() {
	if (data[dataPtr] != 0) {
		return
	}
	programPtr--
	var loop int = 1
	for loop > 0 {
		if (programPtr + 1) >= len(program) {
			fmt.Fprintf(os.Stderr, "\nerror: unmatched [\n")
			terminate(1)
		}
		programPtr++
		var c byte = program[programPtr]
		if c == '[' {
			loop++
		}
		if c == ']' {
			loop--
		}
	}
}

func handleBwdJump() {
	if (data[dataPtr] == 0) {
		return
	}
	programPtr--
	var loop int = 1
	for loop > 0 {
		if (programPtr - 1) < 0 {
			fmt.Fprintf(os.Stderr, "\nerror: unmatched ]\n")
			terminate(1)
		}
		programPtr--
		var c byte = program[programPtr]
		if c == ']' {
			loop++
		}
		if c == '[' {
			loop--
		}
	}
}

func opcodeHandler(op byte) {
	switch op {
	case '>':
		handleNextCell();

	case '<':
		handlePrevCell();

	case '+':
		handleIncrCell();

	case '-':
		handleDecrCell();

	case '.':
		handleOutputCell();

	case ',':
		handleReadCell();

	case '[':
		handleFwdJump();

	case ']':
		handleBwdJump();
	}
}

func loadProgram(fileName string) bool {
	var err error
	program, err = os.ReadFile(fileName)
	if err != nil {
		return false
	}
	fmt.Fprintf(os.Stderr, "loaded program, size: %d\n", len(program));
	return true
}

func main() {
	if len(os.Args) < 2 {
		fmt.Fprintf(os.Stderr, "usage: %s <file>\n", os.Args[0])
		return
	}

	if !loadProgram(os.Args[1]) {
		fmt.Fprintf(os.Stderr, "error: could not open %s\n", os.Args[1])
		return
	}
	data = make([]byte, DATA_ARRAY_SIZE)

	var interrupt chan os.Signal = make(chan os.Signal, 1)
	signal.Notify(interrupt, os.Interrupt)
	go func() {
		<- interrupt
		fmt.Fprintf(os.Stderr, "\naborted\n")
		terminate(0)
	}()
	fmt.Fprintf(os.Stderr, "running, press ctrl+c to abort, press ctrl+d EOF\n")

	var startTime time.Time = time.Now()
	for programPtr < len(program) {
		var op byte = program[programPtr]
		programPtr++
		opcodeHandler(op)
	}

	var execTime int64 = time.Since(startTime).Milliseconds()
	fmt.Fprintf(os.Stderr, "\ndone, took: %d\n", execTime)
	terminate(0)
}
