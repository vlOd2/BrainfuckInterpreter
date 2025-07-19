const DATA_ARRAY_SIZE: number = 30000;
const readBuffer: Uint8Array = new Uint8Array(1);
let data: Uint8Array | undefined = undefined;
let program: Uint8Array | undefined = undefined;
let dataPtr: number = 0;
let programPtr: number = 0;

function handleNextCell() {
    dataPtr++;
    if (dataPtr >= DATA_ARRAY_SIZE) {
        console.error("\nerror: data pointer out of bounds");
        terminate(1);
    }
}

function handlePrevCell() {
    dataPtr--;
    if (dataPtr < 0) {
        console.error("\nerror: data pointer out of bounds");
        terminate(1);
    }
}

function handleIncrCell() {
    data![dataPtr]++;
}

function handleDecrCell() {
    data![dataPtr]--;
}

function handleOutputCell() {
    Deno.stdout.writeSync(data!.slice(dataPtr, dataPtr + 1));
}

function handleReadCell() {
    if (!Deno.stdin.readSync(readBuffer) || readBuffer[0] == 0) {
        return;
    }
    data![dataPtr] = readBuffer[0];
}

function handleFwdJump() {
    if (data![dataPtr] != 0) {
        return;
    }
    programPtr--;
    let loop: number = 1;
    while (loop > 0) {
        if (programPtr + 1 >= program!.length) {
            console.error("\nerror: unmatched [");
            terminate(1);
        }
        const c: string = String.fromCharCode(program![++programPtr]);
        if (c == "[") {
            loop++;
        }
        if (c == "]") {
            loop--;
        }
    }
}

function handleBwdJump() {
    if (data![dataPtr] == 0) {
        return;
    }
    programPtr--;
    let loop: number = 1;
    while (loop > 0) {
        if (programPtr - 1 < 0) {
            console.error("\nerror: unmatched ]");
            terminate(1);
        }
        const c: string = String.fromCharCode(program![--programPtr]);
        if (c == "]") {
            loop++;
        }
        if (c == "[") {
            loop--;
        }
    }
}

function opcodeHandler(op: string) {
    switch (op) {
        case ">":
            handleNextCell();
            break;

        case "<":
            handlePrevCell();
            break;

        case "+":
            handleIncrCell();
            break;

        case "-":
            handleDecrCell();
            break;

        case ".":
            handleOutputCell();
            break;

        case ",":
            handleReadCell();
            break;

        case "[":
            handleFwdJump();
            break;

        case "]":
            handleBwdJump();
            break;

        default:
            // Ignore invalid opcodes
            break;
    }
}

function loadProgram(fileName: string): boolean {
    try {
        program = Deno.readFileSync(fileName);
        console.error(`loaded program, size: ${program.length}`);
        return true;
    } catch {
        return false;
    }
}

function terminate(status: number) {
    data = undefined;
    program = undefined;
    Deno.exit(status);
}

function main(args: string[]) {
    if (args.length < 1) {
        console.error("usage: <file>");
        return;
    }

    if (!loadProgram(args[0])) {
        console.error(`error: could not open: ${args[0]}`);
        return;
    }

    data = new Uint8Array(DATA_ARRAY_SIZE);
    console.error("running, press ctrl+c to abort, press ctrl+d EOF");

    const startTime: number = Date.now();
    while (programPtr < program!.length) {
        const op: string = String.fromCharCode(program![programPtr]);
        programPtr++;
        opcodeHandler(op);
    }

    const execTime: number = Date.now() - startTime;
    console.error(`\ndone, took: ${execTime}`);
    terminate(0);
}

main(Deno.args);