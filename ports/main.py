import os
import sys
import time
import signal

DATA_ARRAY_SIZE = 30001
data = None
program = None
data_ptr = 0
program_ptr = 0

def terminate(status):
    global data
    global program
    data = None
    program = None
    sys.exit(status)

def handle_next_cell():
    global data_ptr
    data_ptr += 1
    if data_ptr >= DATA_ARRAY_SIZE:
        print("\nerror: data pointer out of bounds", file=sys.stderr)
        terminate(1)

def handle_prev_cell():
    global data_ptr
    data_ptr -= 1
    if data_ptr < 0:
        print("\nerror: data pointer out of bounds", file=sys.stderr)
        terminate(1)

def handle_incr_cell():
    global data
    global data_ptr
    data[data_ptr] += 1

def handle_decr_cell():
    global data
    global data_ptr
    data[data_ptr] -= 1

def handle_output_cell():
    global data
    global data_ptr
    print(chr(data[data_ptr]), end='', flush=True)

def handle_read_cell():
    global data
    global data_ptr
    c = sys.stdin.read(1)
    if len(c) == 0: # EOF
        return
    data[data_ptr] = ord(c)

def handle_fwd_jump():
    global data
    global program
    global data_ptr
    global program_ptr
    
    if data[data_ptr] != 0:
        return
    
    program_ptr -= 1
    loop = 1
    while loop > 0:
        if program_ptr + 1 >= len(program):
            print("\nerror: unmatched [", file=sys.stderr)
            terminate(1)
        program_ptr += 1
        c = chr(program[program_ptr])
        if c == "[":
            loop += 1
        if c == "]":
            loop -= 1

def handle_bwd_jump():
    global data
    global program
    global data_ptr
    global program_ptr
    
    if data[data_ptr] == 0:
        return

    program_ptr -= 1
    loop = 1
    while loop > 0:
        if program_ptr - 1 < 0:
            print("\nerror: unmatched ]", file=sys.stderr)
            terminate(1)
        program_ptr -= 1
        c = chr(program[program_ptr])
        if c == "]":
            loop += 1
        if c == "[":
            loop -= 1

def opcode_handler(op):
    if op == ">":
        handle_next_cell()
    elif op == "<":
        handle_prev_cell()
    elif op == "+":
        handle_incr_cell()
    elif op == "-":
        handle_decr_cell()
    elif op == ".":
        handle_output_cell()
    elif op == ",":
        handle_read_cell()
    elif op == "[":
        handle_fwd_jump()
    elif op == "]":
        handle_bwd_jump()

def load_program(name):
    global program
    try:
        file = open(name, mode="rb")
        program = file.read()
        print(f"loaded program, size: {len(program)}", file=sys.stderr)
        return True
    except Exception as ex:
        throw
        return False

def interrupt_handler(sig, frame):
    print("\naborted", file=sys.stderr)
    terminate(0)

def main():
    global data
    global program
    global program_ptr
    
    if len(sys.argv) < 2:
        print(f"usage: {sys.argv[0]} <file>", file=sys.stderr)
        return
    
    if not load_program(sys.argv[1]):
        print(f"error: could not open {sys.argv[1]}", file=sys.stderr)
        return

    data = [0] * DATA_ARRAY_SIZE
    signal.signal(signal.SIGINT, interrupt_handler)
    print("running, press ctrl+c to abort, press ctrl+d EOF", file=sys.stderr)

    start_time = time.time()
    while program_ptr < len(program):
        op = chr(program[program_ptr])
        program_ptr += 1
        opcode_handler(op)
        
    sys.stdout.flush()
    exec_time = (time.time() - start_time) * 1000.0
    print(f"\ndone, took: {exec_time}", file=sys.stderr)
    terminate(0)

if __name__ == "__main__":
    main()
