# BrainfuckInterpreter
Simple brainfuck interpreter written in C<br>
Ports into different languages are available under the ports directory (although no compile scripts, and most have broken EOF/EOL input)

# Features/Quirks
Features that this interpreter has:
- Prints are not buffered and are on stdout
- Interpreter messages are written on stderr
- Reading EOF will not write anything to the cell
- Interrupting (ctrl+c) instantly aborts the execution
- 8-bit or 32-bit data array (must be changed in the source code)

This interpreter passes most of the tests from [here](https://brainfuck.org/tests.b), except for:
- the unmatched \[ \] tests do not pass since the interpreter does not analyse them ahead of time
- the end of line test passes, but only on Linux (due to the lack of EOL consistency)

# Examples
You can find example Brainfuck code (and the test suite) on [brainfuck.org](https://brainfuck.org/)<br>
