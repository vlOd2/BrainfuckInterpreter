import java.nio.file.Files;
import java.nio.file.Paths;

public class Brainfuck {
	private static final int DATA_ARRAY_SIZE = 30000;
	private static byte[] data;
	private static char[] program;
	private static int dataPtr;
	private static int programPtr;
	
	private static void handleNextCell() {
	    dataPtr++;
	    if (dataPtr >= DATA_ARRAY_SIZE) {
	        System.err.printf("\nerror: data pointer out of bounds\n");
	        terminate(1);
	    }
	}

	private static void handlePrevCell() {
	    dataPtr--;
	    if (dataPtr < 0) {
	        System.err.printf("\nerror: data pointer out of bounds\n");
	        terminate(1);
	    }
	}

	private static void handleIncrCell() {
	    data[dataPtr]++;
	}

	private static void handleDecrCell() {
	    data[dataPtr]--;
	}

	private static void handleOutputCell() {
	    System.out.print((char)data[dataPtr]);
	}

	private static void handleReadCell() {
	    int c;
	    try {
	    	c = System.in.read();
	    } catch (Exception ex) {
	    	return;
	    }
	    if (c == -1) {
	        return;
	    }
	    data[dataPtr] = (byte)c;
	}

	private static void handleFwdJump() {
	    if (data[dataPtr] != 0) {
	        return;
	    }
	    programPtr--;
	    int loop = 1;
	    while (loop > 0) {
	        if (programPtr + 1 >= program.length) {
	            System.err.printf("\nerror: unmatched [\n");
	            terminate(1);
	        }
	        char c = program[++programPtr];
	        if (c == '[') {
	        	loop++;
	        }
	        if (c == ']') {
	        	loop--;
	        }
	    }
	}

	private static void handleBwdJump() {
	    if (data[dataPtr] == 0) {
	        return;
	    }
	    programPtr--;
	    int loop = 1;
	    while (loop > 0) {
	        if (programPtr - 1 < 0) {
	            System.err.printf("\nerror: unmatched ]\n");
	            terminate(1);
	        }
	        char c = program[--programPtr];
	        if (c == ']') {
	        	loop++;
	        }
	        if (c == '[') {
	        	loop--;
	        }
	    }
	}
	
	private static void opcodeHandler(char op) {
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
	
	private static boolean loadProgram(String fileName) {
		try {
			byte[] data = Files.readAllBytes(Paths.get(fileName));
			program = new char[data.length];
			for (int i = 0; i < data.length; i++) {
				program[i] = (char)data[i];
			}
			System.err.printf("loaded program, size: %d\n", program.length);
			return true;
		} catch (Exception ex) {
			return false;
		}
	}
	
	private static void terminate(int status) {
		data = null;
		program = null;
		System.exit(status);
	}
	
	public static void main(String[] args) {
		if (args.length < 1) {
			System.err.println("usage: <file>");
			return;
		}
		
		if (!loadProgram(args[0])) {
			System.err.printf("error: could not open: %s\n", args[0]);
			return;
		}
		data = new byte[DATA_ARRAY_SIZE];
		
		Runtime.getRuntime().addShutdownHook(new Thread(() -> {
			System.err.printf("\naborted\n");
			terminate(0);
		}));
		
		long startTime = System.nanoTime();
		while (programPtr < program.length) {
			char op = program[programPtr];
			programPtr++;
			opcodeHandler(op);
		}
		
		System.out.flush();
		double execTime = (System.nanoTime() - startTime) / 1_000_000.0D;
		System.err.printf("\ndone, took: %f\n", execTime);
		terminate(0);
	}
}
