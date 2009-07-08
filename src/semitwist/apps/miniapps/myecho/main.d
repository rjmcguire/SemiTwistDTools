// SemiTwist D Tools
// MiniApps: My Echo
// Written in the D programming language.

/** 
Author:
$(WEB www.semitwist.com, Nick Sabalausky)

This was created to just used to help test the "exec" part of
semitwist.cmd.CommandLine from semitwistlib. Windows "echo" is built into the
commandline and isn't an actual executable, so tango.sys.Process, and
therefore semitwist.cmd.CommandLine, can't launch it.

Uses:
- DMD 1.043
- Tango 0.99.8
*/

module semitwist.apps.miniapps.myecho.main;

import tango.io.Stdout;
import tango.text.Util;

void main(char[][] args)
{
	Stdout( args[1..$].join(" ") ).newline;
}
