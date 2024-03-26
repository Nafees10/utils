/++
	This module contains contains some misc. functions. (The name says that)
+/
module utils.misc;

import std.stdio;
import std.file;
import std.path;
import std.datetime;
import std.datetime.stopwatch;
import std.string : format, chomp;
import std.traits;
import std.conv : to;
import std.algorithm;
import std.functional;

import utils.ds;
public import utils.ds : ByteUnion;

/// Benchmark results from `utils.misc.bench`
struct Times{
	ulong min = ulong.max;
	ulong max = 0;
	ulong total = 0;
	ulong avg = 0;
	string toString() const @safe pure{
		return format!"min\tmax\tavg\ttotal\t/msecs\n%d\t%d\t%d\t%d"(
				min, max, avg, total);
	}
}

/// call `func` for `runs` number of times
/// Returns: benchmark results
Times bench(void delegate(ref StopWatch sw) func, ulong runs = 100_000){
	Times time;
	StopWatch sw = StopWatch(AutoStart.no);
	foreach (i; 0 .. runs){
		func(sw);
		immutable ulong currentTime = sw.peek.total!"msecs" - time.total;
		time.min = currentTime < time.min ? currentTime : time.min;
		time.max = currentTime > time.max ? currentTime : time.max;
		time.total = sw.peek.total!"msecs";
	}
	time.avg = time.total / runs;
	return time;
}

/// call `func` for `runs` number of times
/// Returns: benchmark results
Times bench(void delegate() func, ulong runs = 100_000){
	Times time;
	StopWatch sw = StopWatch(AutoStart.no);
	foreach (i; 0 .. runs){
		sw.start();
		func();
		sw.stop();
		immutable ulong currentTime = sw.peek.total!"msecs" - time.total;
		time.min = currentTime < time.min ? currentTime : time.min;
		time.max = currentTime > time.max ? currentTime : time.max;
		time.total = sw.peek.total!"msecs";
	}
	time.avg = time.total / runs;
	return time;
}

/// mangles an unsigned integer, using a key.
/// is reversible. calling this on a mangled integer will un-mangle it
deprecated size_t mangle(size_t val, size_t key) pure {
	static const bits = size_t.sizeof * 8;
	size_t ret = ~key & val;
	for (ubyte i = 0; i < bits; i ++){
		if ((key >> i) & 1){
			immutable ubyte s1 = i;
			for (i ++; i < bits; i ++){
				if ((key >> i) & 1)
					break;
			}
			if (i == size_t.sizeof * 8){
				ret |= ((val >> s1) & 1) << s1;
				break;
			}
			immutable ubyte s2 = i;
			// magic:
			ret |= (((val >> s2) & 1) << s1) | (((val >> s1) & 1) << s2);
		}
	}
	return ret;
}

///
unittest{
	import std.random : uniform;
	assert(mangle(0b0010, 0b0011) == 0b0001);
	assert(mangle(mangle(0b0010, 0b0011), 0b0011) == 0b0010);

	size_t val = uniform(0, size_t.max), key = uniform(0, size_t.max);
	assert(mangle(mangle(val, key), key) == val, val.to!string ~ ' ' ~ key.to!string);
}

/// mangles using a key available at compile time.
/// is reversible, calling mangled integer with same key will return un-mangled integer
deprecated size_t mangle(size_t key)(size_t val) pure {
	static size_t rmOdd(size_t key) pure{
		size_t ret;
		for (ubyte i = 0; i < size_t.sizeof * 8; i ++){
			if ((key >> i) & 1){
				immutable ubyte s1 = i;
				for (i ++; i < size_t.sizeof * 8; i ++){
					if ((key >> i) & 1){
						ret |= (1LU << s1) | (1LU << i);
						break;
					}
				}
			}
		}
		return ret;
	}

	static ushort[size_t.sizeof * 4] swapPos(size_t key) pure{
		ushort[size_t.sizeof * 4] ret;
		ubyte count;
		for (ubyte i = 0; i < size_t.sizeof * 8; i ++){
			if ((key >> i) & 1){
				immutable ubyte index = i;
				for (i ++; i < size_t.sizeof * 8; i ++){
					if ((key >> i) & 1){
						ret[count++] = cast(ushort)((i << 8) | index);
						break;
					}
				}
			}
		}
		return ret;
	}

	static const actualKey = rmOdd(key);
	static const ushort[size_t.sizeof * 4] swaps = swapPos(actualKey);
	size_t ret = ~actualKey & val;
	static foreach (pos; swaps){
		static if (pos){
			ret |=  (((val >> (pos & ubyte.max)) & 1) << ((pos >> 8) & ubyte.max))|
					(((val >> ((pos >> 8) & ubyte.max)) & 1) << (pos & ubyte.max));
		}
	}
	return ret;
}

///
unittest{
	import std.random : uniform;

	size_t val = uniform(0, size_t.max);
	immutable size_t key = 2_294_781_104_715_578_999;
	assert(mangle!key(mangle!key(val)) == val);
}

/// Generates combinations for enum with bitflag members
/// T, the enum, must have base type as ulong
deprecated ulong[] combinations(T)(ulong alwaysIncluded = 0, ulong alwaysExcluded = 0)
		pure if (is(T == enum) && is(OriginalType!(Unqual!T) == ulong)){
	ulong[] ret;
	immutable ulong ignore = alwaysIncluded & ~alwaysExcluded;
	ulong val = ignore;
	do{
		foreach (i; EnumMembers!T){
			if (i & ignore)
				continue;
			if (i & val){
				val &= ~i;
			}else{
				val |= i;
				break;
			}
		}
		ret ~= val;
	}while (val != ignore);
	return ret;
}

///
unittest{
	enum Vals : ulong{
		One		= 1,
		Two		= 2,
		Four	= 4,
		Eight	= 8,
	}
	ulong[] list = combinations!Vals();
	foreach (i; 0 .. 16)
		assert(list.canFind(i));
	assert(list.length == 16);
}

/// Converts bitflags to comma separated readable string for enums
/// T is an enum, with ulong base type
deprecated string bitmaskToString(T, char ENCLOSE=0)(ulong flags) pure
		if (is(T == enum) && is(OriginalType!(Unqual!T) == ulong)){
	string str;
	foreach (i; EnumMembers!T){
		if (i & flags){
			static if (ENCLOSE == 0)
				str ~= to!string(i) ~ ',';
			else
				str ~= ENCLOSE ~ to!string(i) ~ ENCLOSE ~ ',';
		}
	}
	if (str.length)
		return str[0 .. $ - 1];
	return str;
}

///
unittest{
	enum Vals : ulong{
		One			=	1,
		Two			=	2,
		Four		=	4,
		ThirtyTwo	=	32
	}
	assert (bitmaskToString!Vals(3) == "One,Two");
	assert (bitmaskToString!Vals(33) == "One,ThirtyTwo");
	assert (bitmaskToString!(Vals,'`')(3) == "`One`,`Two`");
	assert (bitmaskToString!(Vals,'`')(33) == "`One`,`ThirtyTwo`");
}

/// Reads a file into array of string
///
/// each element in the returned array is a separate line, excluding the trailing `\n` character
///
/// Returns: the lines read from file in array of string
///
/// Throws: Exception on failure
deprecated string[] fileToArray(string fname){
	File f = File(fname, "r");
	string[] r;
	while (!f.eof())
		r ~= f.readln.chomp("\n");
	f.close();
	return r;
}

/// Writes an array of string to a file
///
/// If a file already exists, it will be overwritten, and `\n` is added at end of each string
///
/// Throws: exception on failure
deprecated void arrayToFile(string[] array, string fname, string toApp = "\n"){
	File f = File(fname,"w");
	foreach (val; array)
		f.write(val, toApp);
	f.close();
}

/// Reads a hexadecimal number from string
///
/// Returns: the number in a size_t
///
/// Throws: Exception in case string is not a hexadecimal number, or too big to store in size_t, or empty string
size_t readHexadecimal(string str){
	import std.range : iota, array;
	if (str.length == 0)
		throw new Exception("cannot read hexadecimal number from empty string");
	if (str.length > size_t.sizeof * 2) // str.length / 2 = numberOfBytes
		throw new Exception("hexadecimal number is too big to store in size_t");
	static char[16] DIGITS = iota('0', '9'+1).array ~ iota('a', 'f'+1).array;
	str = str.lowercase;
	if (!(cast(char[])str).matchElements(DIGITS))
		throw new Exception("invalid character in hexadecimal number");
	size_t r;
	immutable size_t lastInd = cast(uint)str.length - 1;
	foreach (i, c; str)
		r |= DIGITS.indexOf(c) << 4 * (lastInd - i);
	return r;
}

///
unittest{
	assert("FF".readHexadecimal == 0xFF);
	assert("F0".readHexadecimal == 0xF0);
	assert("EF".readHexadecimal == 0xEF);
	assert("A12f".readHexadecimal == 0xA12F);
}

/// Reads a binary number from string
///
/// Returns: the number in a size_t
///
/// Throws: Exception in case string is not a binary number, or too big to store in size_t, or empty string
size_t readBinary(string str) pure {
	if (str.length == 0)
		throw new Exception("cannot read binary number from empty string");
	if (str.length > size_t.sizeof * 8)
		throw new Exception("binary number is too big to store in size_t");
	if (!(cast(char[])str).matchElements(['0','1']))
		throw new Exception("invalid character in binary number");
	size_t r;
	immutable size_t lastInd = cast(uint)str.length - 1;
	foreach (i, c; str)
		r |= (c == '1') << (lastInd - i);
	return r;
}

///
unittest{
	assert("01010101".readBinary == 0B01010101);
}

/// Returns: true if array contains all elements provided in an array
deprecated bool hasElement(T)(T[] array, T[] elements) pure {
	// go through the list and match as many elements as possible
	foreach (val; elements){
		if (array.indexOf(val) == -1)
			return false;
	}
	return true;
}

///
unittest{
	assert([0, 1, 2].hasElement([2, 0, 1]) == true);
	assert([0, 1, 2].hasElement([2, 0, 1, 1, 0, 2]) == true); // it works different-ly from `LinkedList.hasElements`
	assert([0, 1, 2].hasElement([1, 2]) == true);
	assert([0, 1, 2].hasElement([2, 4]) == false);
}

/// Checks if all elements present in an array are also present in another array
///
/// Index, and the number of times the element is present in each array doesn't matter
///
///
/// Arguments:
/// `toMatch` is the array to perform the check on
/// `elements` is the array containing the elements that will be compared against
///
/// Returns: true if all elements present in `toMatch` are also present in `elements`
deprecated bool matchElements(T)(T[] toMatch, T[] elements) pure {
	foreach(currentToMatch; toMatch){
		if (!elements.canFind(currentToMatch))
			return false;
	}
	return true;
}

///
unittest{
	assert("Hello".matchElements("aeloH") == true);
	assert("abcd".matchElements("cda") == false);
}

/// Returns: the index of an element in an array, negative one if not found
deprecated ptrdiff_t indexOf(T)(T[] array, T element) pure {
	foreach (i, val; array){
		if (val == element)
			return i;
	}
	return -1;
}

///
unittest{
	assert([0, 1, 2].indexOf(1) == 1);
	assert([0, 1, 2].indexOf(4) == -1);
}

/// Returns index of closing/openinig bracket of the provided bracket
///
/// `T` is data type of each element (usually char in case of searching in strings)
/// `forward` if true, then the search is in forward direction, i.e, the closing bracket is searched for
/// `opening` is the array of elements that are to be considered as opening brackets
/// `closing` is the array of elements that are to be considered as closing brackets. Must be in same order as `opening`
/// `s` is the array to search in
/// `index` is the index of the opposite bracket
///
/// Returns: index of closing/opening bracket
///
/// Throws: Exception if the bracket is not found
deprecated size_t bracketPos(T, bool forward=true)
		(T[] s, size_t index, T[] opening=['[','{','('], T[] closing=[']','}',')'])
		{
	Stack!T brackets = new Stack!T;
	size_t i = index;
	for (immutable size_t lastInd = (forward ? s.length : 0); i != lastInd; (forward ? i ++: i --)){
		if ((forward ? opening : closing).canFind(s[i])){
			// push it to brackets
			brackets.push(s[i]);
		}else if ((forward ? closing : opening).canFind(s[i])){
			// make sure the correct bracket was closed
			if ((forward ? opening : closing).indexOf(s[i]) !=
				(forward ? closing : opening).indexOf(brackets.pop)){
				throw new Exception("incorect brackets order - first opened must be last closed");
			}
		}
		if (brackets.count == 0){
			break;
		}
	}
	.destroy (brackets);
	return i;
}

///
unittest{
	assert ((cast(char[])"hello(asdf[asdf])").bracketPos(5) == 16);
	assert ((cast(char[])"hello(asdf[asdf])").bracketPos(10) == 15);
}

/*
/// divides an array into number of arrays while (trying to) keeping their length same
///
/// In case it's not possible to keep length same, the left-over elements from array will be added to the last array
///
/// Returns: the divided arrays
T[][] divideArray(T)(T[] array, size_t divBy){
	array = array.dup;
	T[][] r;
	r.length = divBy;
	size_t elementCount = array.length / divBy;
	if (elementCount == 0){
		r[0] = array;
		return r;
	}
	foreach (i, element; r){
		if (elementCount > array.length){
			break;
		}
		r[i] = array[0 .. elementCount].dup;
		array = array[elementCount .. array.length];
	}
	// check if there's some elements left, append them to end of last array, to keep the order
	if (array.length > 0){
		r[divBy-1] = r[divBy-1] ~ array;
	}
	return r;
}
///
unittest{
	import std.conv : to;
	assert ([0,1,2,3,4,5].divideArray(2) == [[0,1,2],[3,4,5]]);
	assert ([0,1,2,3,4,5,6,7].divideArray(3) == [[0,1],[2,3],[4,5,6,7]]);
	assert ([0,1].divideArray(3) == [[0,1],[],[]]);
}*/

/// Divides an array into smaller arrays, where smaller arrays have a max size
///
/// Returns: array of the smaller arrays
deprecated T[][] divideArray(T)(T[] array, size_t maxLength) pure {
	if (maxLength == 0)
		throw new Exception("maxLength must be greater than 0");
	T[][] r;
	r.length = (array.length / maxLength) + (array.length % maxLength == 0 ? 0 : 1);
	for (size_t readFrom = 0, i = 0; i < r.length; i ++){
		if (readFrom + maxLength > array.length){
			r[i] = array[readFrom .. array.length];
		}else{
			r[i] = array[readFrom .. readFrom + maxLength];
			readFrom += maxLength;
		}
	}
	return r;
}

///
unittest{
	assert([0,1,2,3].divideArray(1) == [[0],[1],[2],[3]]);
	assert([0,1,2,3].divideArray(2) == [[0,1],[2,3]]);
	assert([0,1,2,3].divideArray(3) == [[0,1,2],[3]]);
	assert([0,1,2,3].divideArray(4) == [[0,1,2,3]]);
}

/// Returns: true if a string is a number
bool isNum(string s, bool allowDecimalPoint=true) pure {
	bool hasDecimalPoint = false;
	if (!allowDecimalPoint)
		hasDecimalPoint = true; // hack
	if (s.length > 0 && s[0] == '-')
		s = s[1 .. $];
	if (s.length == 0)
		return false;
	foreach (c; s){
		if (c == '.' && !hasDecimalPoint){
			hasDecimalPoint = true;
		}else if (!"0123456789".canFind(c)){
			return false;
		}
	}
	return true;
}

///
unittest{
	assert("32".isNum == true);
	assert("32.2".isNum == true);
	assert("32.2.4".isNum == false);
	assert("5.a".isNum == false);
	assert("thisIsAVar_1234".isNum == false);
	assert("5.3".isNum(false) == false);
	assert("53".isNum(false) == true);
	assert("-53".isNum(false) == true);
	assert("-53".isNum(true) == true);
	assert("-53.0".isNum(false) == false);
	assert("-53.8".isNum(true) == true);
	assert("-".isNum == false);
	assert("".isNum == false);
}

/// Returns: a string with all uppercase alphabets converted into lowercase
/// TODO: deprecate it?
string lowercase(string s) pure {
	static immutable ubyte diff = 'a' - 'A';
	char[] r = (cast(char[])s).dup;
	foreach (ref c; r){
		if (c >= 'A' && c <= 'Z')
			c = cast(char)(c+diff);
	}
	return cast(string)r;
}

///
unittest{
	assert("ABcD".lowercase == "abcd");
	assert("abYZ".lowercase == "abyz");
}

/// Returns: true if all characters in a string are alphabets, uppercase, lowercase, or both
/// TODO: deprecate it?
bool isAlphabet(string s) pure {
	foreach (c; s){
		if ((c < 'a' || c > 'z') && (c < 'A' || c > 'Z')){
			return false;
		}
	}
	return true;
}

///
unittest{
	assert("aBcDEf".isAlphabet == true);
	assert("ABCd_".isAlphabet == false);
	assert("ABC12".isAlphabet == false);
}
