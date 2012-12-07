// SemiTwist Library
// Written in the D programming language.

module semitwist.util.array;

import std.algorithm;
import std.array;
import std.conv;
import std.functional;
import std.random;
import std.range;

import semitwist.util.all;

private alias std.algorithm.map map;

class MissingKeyException : Exception
{
	string key;
	this(string key)
	{
		this.key = key;
		super(text("Required key '", key, "' is missing"));
	}
}

size_t maxLength(T)(T[][] arrays)
{
	size_t maxLen=0;
	foreach(T[] array; arrays)
		maxLen = max(maxLen, array.length);
	return maxLen;
}

size_t indexOfMin(T)(T[] array)
{
	T best = T.max;
	size_t bestIndex;
	foreach(size_t i, T elem; array)
	{
		if(elem < best)
		{
			best = elem;
			bestIndex = i;
		}
	}
	return bestIndex;
}

size_t indexOfMax(T)(T[] array)
{
	T best = T.min;
	size_t bestIndex;
	foreach(size_t i, T elem; array)
	{
		if(elem > best)
		{
			best = elem;
			bestIndex = i;
		}
	}
	return bestIndex;
}

//TODO: eliminate name collision with tango.text.Util
//TODO: Is this the same as tango.core.Array.findIf()?
/+size_t find(T)(T[] collection, bool delegate(T[], size_t) isFound, size_t start=0)
{
	for(size_t i=start; i<collection.length; i++)
	{
		if(isFound(collection, i))
			return i;
	}
	
	return collection.length;
}
+/
size_t findPrior(T)(T[] collection, bool delegate(T[], size_t) isFound, size_t start=(size_t).max)
{
	if(start == (size_t).max)
		start = collection.length-1;
		
	for(size_t i=start; i >= 0; i--)
	{
		if(isFound(collection, i))
			return i;
	}

	return collection.length;
}

/// Returns everything in 'from' minus the values in 'except'.
// Note: using ref didn't work when params were (const string[] here).dup
T allExcept(T)(T from, T except)
{
	T f = from.dup;
	T e = except.dup;
	f.sort();
	e.sort();
	return f.missingFrom(e);
}
T[] allExcept(T)(T[] from, T except)
{
	return allExcept(from, [except]);
}

/// Ex: toRangedPairs([3,4,5,5,6,6,10,25,26]) == [[3,6], [10,10], [25,26]]
/// Only intended for integer types and other ordered types for which "x+1" makes sense.
/// Input does not have to be sorted.
/// The resulting pairs are sorted and are inclusive on both ends.
/// Optionally takes a splitCond predicate so you can customize when the range ends.
T[2][] toRangedPairs(alias splitCond = "b > a + 1", T)(T[] arr)
{
    alias binaryFun!(splitCond) splitCondDg;
    static if(!is(typeof(splitCondDg(T.init, T.init)) == bool))
        static assert(false, "Invalid predicate passed to toRangedPairs: "~splitCond);

	if(arr.length == 0)
		return [];
	
	if(arr.length == 1)
		return [ [ arr[0], arr[0] ] ];
		
	arr = array(sort(arr));
	
	T[2][] ret;
	auto prevVal  = arr[0];
	auto startVal = arr[0];
	foreach(val; arr[1..$])
	{
		if(splitCondDg(prevVal, val))
		{
			ret ~= [ startVal, prevVal ];
			startVal = val;
		}
		prevVal = val;
	}
	ret ~= [ startVal, arr[$-1] ];
	
	return ret;
}

/// If 'haystack' begins with 'needle', remove 'needle'
T[] removeLeft(T)(T[] haystack, T[] needle)
{
	if(haystack.startsWith(needle))
		haystack = haystack[needle.length .. $];
	
	return haystack;
}

/// If 'haystack' ends with 'needle', remove 'needle'
T[] removeRight(T)(T[] haystack, T[] needle)
{
	if(haystack.endsWith(needle))
		haystack = haystack[0 .. $-needle.length];
	
	return haystack;
}

TVal getRequired(TVal, TKey)(TVal[TKey] aa, TKey key)
{
	if(auto valPtr = key in aa)
		return *valPtr;
	else
		throw new MissingKeyException(key);
}

ubyte[] randomBytes(size_t numBytes)
{
	return
		Random(unpredictableSeed)
			.map!( (x) => cast(ubyte)x )()
			.take(numBytes)
			.array();
}

mixin(unittestSemiTwistDLib(q{

	// toRangedPairs
	mixin(deferEnsure!(q{ [12,3,7,4,10,5,9,12].toRangedPairs() }, q{ _ == [[3,5], [7,7], [9,10], [12,12]] }));
	mixin(deferEnsure!(q{ [1,20].toRangedPairs() }, q{ _ == [[1,1], [20,20]] }));

	// removeLeft
	mixin(deferEnsure!(q{ removeLeft("abcde", "ab") }, q{ _ == "cde" }));
	mixin(deferEnsure!(q{ removeLeft("abcde", "aX") }, q{ _ == "abcde" }));
	mixin(deferEnsure!(q{ removeLeft("abcde", "Xb") }, q{ _ == "abcde" }));
	mixin(deferEnsure!(q{ removeLeft("abcde", "XX") }, q{ _ == "abcde" }));
	mixin(deferEnsure!(q{ removeLeft([1,2,3,4], [1,2]) }, q{ _ == [3,4] }));
	mixin(deferEnsure!(q{ removeLeft([1,2,3,4], [9,9]) }, q{ _ == [1,2,3,4] }));

	// removeRight
	mixin(deferEnsure!(q{ removeRight("abcde", "de") }, q{ _ == "abc" }));
	mixin(deferEnsure!(q{ removeRight("abcde", "Xe") }, q{ _ == "abcde" }));
	mixin(deferEnsure!(q{ removeRight("abcde", "dX") }, q{ _ == "abcde" }));
	mixin(deferEnsure!(q{ removeRight("abcde", "XX") }, q{ _ == "abcde" }));
	mixin(deferEnsure!(q{ removeRight([1,2,3,4], [3,4]) }, q{ _ == [1,2] }));
	mixin(deferEnsure!(q{ removeRight([1,2,3,4], [9,9]) }, q{ _ == [1,2,3,4] }));
	
}));
