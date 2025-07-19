<?php
	define("DATA_ARRAY_SIZE", 30000);
	
	$data = null;
	$program = null;
	$dataPtr = 0;
	$programPtr = 0;

	function terminate(int $status) {
		global $data;
		global $program;
		$data = null;
		$program = null;
		exit($status);
	}

	function handleNextCell() {
		global $dataPtr;
		$dataPtr++;
		if ($dataPtr >= DATA_ARRAY_SIZE) {
			fprintf(STDERR, "\nerror: data pointer out of bounds\n");
			terminate(1);
		}
	}

	function handlePrevCell() {
		global $dataPtr;
		$dataPtr--;
		if ($dataPtr < 0) {
			fprintf(STDERR, "\nerror: data pointer out of bounds\n");
			terminate(1);
		}
	}

	function handleIncrCell() {
		global $data;
		global $dataPtr;
		$data[$dataPtr]++;
	}

	function handleDecrCell() {
		global $data;
		global $dataPtr;
		$data[$dataPtr]--;
	}

	function handleOutputCell() {
		global $data;
		global $dataPtr;
		fputs(STDOUT, chr($data[$dataPtr]));
	}

	function handleReadCell() {
		global $data;
		global $dataPtr;
		$c = fgetc(STDIN);
		if ($c === false) {
			return;
		}
		$data[$dataPtr] = ord($c);
	}

	function handleFwdJump() {
		global $data;
		global $program;
		global $dataPtr;
		global $programPtr;
		
		if ($data[$dataPtr] !== 0) {
			return;
		}
		
		$programPtr--;
		$loop = 1;
		while ($loop > 0) {
			if ($programPtr + 1 >= count($program)) {
				fprintf(STDERR, "\nerror: unmatched [\n");
				terminate(1);
			}
			$programPtr++;
			$c = chr($program[$programPtr]);
			if ($c === "[") {
				$loop++;	
			}
			if ($c === "]") {
				$loop--;
			}
		}
	}

	function handleBwdJump() {
		global $data;
		global $program;
		global $dataPtr;
		global $programPtr;
		
		if ($data[$dataPtr] === 0) {
			return;
		}
		
		$programPtr--;
		$loop = 1;
		while ($loop > 0) {
			if ($programPtr - 1 < 0) {
				fprintf(STDERR, "\nerror: unmatched ]\n");
				terminate(1);
			}
			$programPtr--;
			$c = chr($program[$programPtr]);
			if ($c === "]") {
				$loop++;
			}
			if ($c === "[") {
				$loop--;
			}
		}
	}

	function opcodeHandler(string $op) {
		switch ($op) {
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

	function readProgram(string $fileName): bool {
		try {
			global $program;
			$program = SplFixedArray::fromArray(unpack("C*", file_get_contents($fileName, true)), false);
			fprintf(STDERR, "loaded program, size: %d\n", count($program));
			return true;
		} catch (Exception) {
			return false;
		}
	}

	function main() {
		global $argv;
		global $data;
		global $program;
		global $programPtr;
		
		if (count($argv) < 2) {
			fprintf(STDERR, "usage: %s <file>\n", $argv[0]);
			return;
		}
		
		if (!readProgram($argv[1])) {
			fprintf(STDERR, "error: failed to open %s\n", $argv[1]);
			return;
		}
		$data = array_fill(0, DATA_ARRAY_SIZE, 0);
		
		fprintf(STDERR, "running, press ctrl+c to abort, press ctrl+d EOF\n");
		
		$startTime = microtime(true);
		while ($programPtr < count($program)) {
			$op = $program[$programPtr];
			$programPtr++;
			opcodeHandler(chr($op));
		}
		
		fflush(STDOUT);
		$execTime = (microtime(true) - $startTime) * 1000.0;
		fprintf(STDERR, "\ndone, took: %f\n", $execTime);
		terminate(0);
	}
	
	if (php_sapi_name() != "cli") {
		die("You must run this from the php CLI");
	}
	main();
?>