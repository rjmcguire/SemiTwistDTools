// SemiTwist Library
// Written in the D programming language.

module semitwist.util.process;

import std.conv;
import std.file;
import std.process;
import std.stream;
import std.string;

version(Windows)
{
	import core.sys.windows.windows;
	extern(Windows) int CreatePipe(
		HANDLE* hReadPipe,
		HANDLE* hWritePipe,
		SECURITY_ATTRIBUTES* lpPipeAttributes,
		uint nSize);
}

import semitwist.util.all;
import semitwist.util.compat.all;

void createPipe(out HANDLE readHandle, out HANDLE writeHandle)
{
	version(Windows)
	{
		auto secAttr = SECURITY_ATTRIBUTES(SECURITY_ATTRIBUTES.sizeof, null, true);
		if(!CreatePipe(&readHandle, &writeHandle, &secAttr, 0))
			throw new Exception("Couldn't create pipe");
	}
	else
	{
		int[2] pipeHandles;
		if(pipe(pipeHandles) != 0)
			throw new Exception("Couldn't create pipe");
		readHandle  = pipeHandles[0];
		writeHandle = pipeHandles[1];
	}
}

//TODO: Support string/wstring in addition to char[]/wchar[]
TRet eval(TRet)(string code, string imports="", string rdmdOpts="")
{
	enum boilerplate = q{
		import std.conv;
		import std.process;
		import std.stream;
		import std.string;
		version(Windows) import std.c.windows.windows;
		%s
		alias %s TRet;
		void main(string[] args)
		{
			static if(is(TRet==void))
				_main();
			else
			{
				if(args.length < 2 || !std.string.isNumeric(args[1]))
					throw new Exception("First arg must be file handle for the return value");

				auto writeHandle = cast(HANDLE)std.conv.to!size_t(args[1]);
				auto retValWriter = new std.stream.File(writeHandle, FileMode.Out);

				auto ret = _main();
				retValWriter.write(ret);
			}
		}
		TRet _main()
		{
			%s
		}
	}.normalize();
	
	code = boilerplate.format(imports, TRet.stringof, code);
	
	HANDLE retValPipeRead;
	HANDLE retValPipeWrite;
	static if(!is(TRet==void))
	{
		createPipe(retValPipeRead, retValPipeWrite);
		auto retValReader = new File(retValPipeRead, FileMode.In);
	}
	
	auto tempName = "eval_st_"~md5(code);
	write(tempName~".d", code);

	//TODO: On Win, create rdmdAlt if it isn't already there
	auto rdmdName = "rdmd";
	version(Windows)
		rdmdName = "rdmdAlt";

	auto errlvl = system(rdmdName~" "~rdmdOpts~" "~tempName~" "~to!string(cast(size_t)retValPipeWrite));
	//TODO: Clean temp files
	if(errlvl != 0)
		//TODO: Include failure text, and what part failed: compile or execution
		throw new Exception("eval failed");
	
	static if(is(TRet==void))
		return;
	else
	{
		TRet retVal;
		retValReader.read(retVal);
		return retVal;
	}
}

unittest
{
	//enum test_eval1 = q{ eval!int(q{ writeln("Hello World!"); return 7; }, q{ import std.stdio; }) };
	//mixin(deferEnsure!(test_eval1, q{ _==7 }));

	enum test_eval2 = q{ eval!int(q{ return 42; }) };
	mixin(deferEnsure!(test_eval2, q{ _==42 }));

	enum test_eval3 = q{ eval!(char[])(q{ return "Test string".dup; }) };
	mixin(deferEnsure!(test_eval3, q{ _=="Test string" }));

	enum test_eval4 = q{ eval!void(q{ return; }) };
	//mixin(deferEnsure!(test_eval4, q{ true })); //TODO: Fix error: "voids have no value"
	mixin(test_eval4~";");
}