using System;
using System.IO;
using System.Diagnostics;

public static class Brainfuck 
{
	private const int DATA_ARRAY_SIZE = 30000;
	private static byte[] data;
	private static char[] program;
	private static int dataPtr;
	private static int programPtr;
	
	private static void HandleNextCell() 
	{
	    dataPtr++;
	    if (dataPtr >= DATA_ARRAY_SIZE) 
		{
	        Console.Error.WriteLine("\nerror: data pointer out of bounds");
	        Terminate(1);
	    }
	}

	private static void HandlePrevCell() 
	{
	    dataPtr--;
	    if (dataPtr < 0) 
		{
	        Console.Error.WriteLine("\nerror: data pointer out of bounds");
	        Terminate(1);
	    }
	}

	private static void HandleIncrCell() 
	{
	    data[dataPtr]++;
	}

	private static void HandleDecrCell() 
	{
	    data[dataPtr]--;
	}

	private static void HandleOutputCell() 
	{
	    Console.Write((char)data[dataPtr]);
	}

	private static void HandleReadCell() 
	{
	    int c = Console.Read();
	    if (c == -1) return;
	    data[dataPtr] = (byte)c;
	}

	private static void HandleFwdJump() 
	{
	    if (data[dataPtr] != 0) 
	        return;
	    programPtr--;
	    int loop = 1;
	    while (loop > 0) 
		{
	        if (programPtr + 1 >= program.Length) 
			{
	            Console.Error.WriteLine("\nerror: unmatched [");
	            Terminate(1);
	        }
	        char c = program[++programPtr];
	        if (c == '[') loop++;
	        if (c == ']') loop--;
	    }
	}

	private static void HandleBwdJump() 
	{
	    if (data[dataPtr] == 0) 
	        return;
	    programPtr--;
	    int loop = 1;
	    while (loop > 0) 
		{
	        if (programPtr - 1 < 0) 
			{
				Console.Error.WriteLine("\nerror: unmatched ]");
	            Terminate(1);
	        }
	        char c = program[--programPtr];
	        if (c == ']') loop++;
	        if (c == '[') loop--;
	    }
	}
	
	private static void OpcodeHandler(char op) 
	{
	    switch (op) 
		{
	        case '>':
	            HandleNextCell();
	            break;

	        case '<':
	            HandlePrevCell();
	            break;

	        case '+':
	            HandleIncrCell();
	            break;
	            
	        case '-':
	            HandleDecrCell();
	            break;
	            
	        case '.':
	            HandleOutputCell();
	            break;

	        case ',':
	            HandleReadCell();
	            break;

	        case '[':
	            HandleFwdJump();
	            break;

	        case ']':
	            HandleBwdJump();
	            break;

	        default:
	            // Ignore invalid opcodes
	            break;
	    }
	}
	
	private static bool LoadProgram(String fileName) 
	{
		try 
		{
			byte[] data = File.ReadAllBytes(fileName);
			program = new char[data.Length];
			for (int i = 0; i < data.Length; i++)
				program[i] = (char)data[i];
			Console.Error.WriteLine("loaded program, size: " + program.Length);
			return true;
		} 
		catch 
		{
			return false;
		}
	}
	
	private static void Terminate(int status) 
	{
		data = null;
		program = null;
		Environment.Exit(status);
	}

	public static void Main(string[] args) 
	{
		if (args.Length < 1)
		{
			Console.Error.WriteLine("usage: <file>");
			return;
		}
		
		if (!LoadProgram(args[0]))
		{
			Console.Error.WriteLine("error: could not open: " + args[0]);
			return;
		}
		
		data = new byte[DATA_ARRAY_SIZE];
		Console.Error.WriteLine("running, press ctrl+c to abort, press ctrl+d EOF");
		
		Stopwatch stopwatch = Stopwatch.StartNew();
		while (programPtr < program.Length) 
		{
			char op = program[programPtr];
			programPtr++;
			OpcodeHandler(op);
		}
		stopwatch.Stop();
		
		Console.Out.Flush();
		Console.Error.WriteLine("\ndone, took: " + stopwatch.ElapsedMilliseconds);
		Terminate(0);
	}
}