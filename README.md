# BrainfuckInterpreter
Simple brainfuck interpreter written in C

# Implementation notes
- Prints are not buffered and are on stdout
- Interpreter messages are written on stderr
- Reading EOF will not write anything to the cell
- Interrupting (ctrl+c) instantly aborts the execution

# Examples
You can find a lot of example BF code on [brainfuck.org](https://brainfuck.org/)<br>
Some of them may not work properly due to comments not being escaped