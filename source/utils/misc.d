/++
	This module contains contains some misc. functions. (The name says that)
+/
module utils.misc;

import std.stdio;
import std.file;
import std.path;
import std.datetime;
import std.datetime.stopwatch;
import std.string : format;

import utils.ds;
public import utils.ds : ByteUnion;

struct Times{
	ulong min = ulong.max;
	ulong max = 0;
	ulong total = 0;
	ulong avg = 0;
	string toString() const @safe pure{
		return format!"min\tmax\tavg\ttotal\t/msecs\n%d\t%d\t%d\t%d"(min, max, avg, total);
	}
}

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

/// Reads a file into array of string
///
/// each element in the returned array is a separate line, excluding the trailing `\n` character
/// 
/// Returns: the lines read from file in array of string
/// 
/// Throws: Exception on failure
string[] fileToArray(string fname){
	File f = File(fname,"r");
	string[] r;
	string line;
	ptrdiff_t i=0;
	r.length=0;
	while (!f.eof()){
		if (i+1>=r.length){
			r.length+=5;
		}
		line=f.readln;
		if (line.length>0 && line[line.length-1]=='\n'){
			line.length--;
		}
		r[i]=line;
		i++;
	}
	f.close;
	r.length = i;
	return r;
}

/// Writes an array of string to a file
/// 
/// If a file already exists, it will be overwritten, and `\n` is added at end of each string
/// 
/// Throws: exception on failure
void arrayToFile(string[] array, string fname){
	File f = File(fname,"w");
	size_t i;
	for (i=0;i<array.length;i++){
		f.write(array[i],'\n');
	}
	f.close;
}

/// uses `listdir` to list files/dirs in a dir, and filters the ones that were modified after a given time
/// 
/// if the provided dir has subdirs, those are also checked, and so on
///
/// Arguments:
/// `filePath` is the path to the dir/file to check  
/// `lastTime` is the time to check against  
/// `exclude` is a list of files/dirs to not to include in the check  
/// 
/// Returns: the absolute paths of the files/dirs modified after the time
string[] filesModified(string filePath, SysTime lastTime, string[] exclude = []){
	import std.algorithm;
	import std.array;
	
	// make sure the filePath is not in exclude
	if (exclude.indexOf(filePath) >= 0){
		return [];
	}
	if (filePath.isDir){
		LinkedList!string modifiedList = new LinkedList!string;
		FIFOStack!string filesToCheck = new FIFOStack!string;
		filesToCheck.push(listDir(filePath));
		// go through the stack
		while (filesToCheck.count > 0){
			string file = filesToCheck.pop;
			if (!isAbsolute(file)){
				file = absolutePath(filePath~'/'~file);
			}
			if (exclude.indexOf(file) >= 0){
				continue;
			}
			// check if it's a dir, case yes, push it's files too
			if (file.isDir){
				filesToCheck.push(listDir(file));
			}else if (file.isFile){
				// is file, check if it was modified
				if (timeLastModified(file) > lastTime){
					modifiedList.append(absolutePath(file));
				}
			}
		}
		string[] r = modifiedList.toArray;
		.destroy (modifiedList);
		.destroy (filesToCheck);
		return r;
	}else{
		if (timeLastModified(filePath) > lastTime){
			return [filePath];
		}
	}
	return [];
}

/// lists the files and dirs inside a dir
///
/// only dirs and files are returned, symlinks are ignored
/// 
/// Returns: an array containing absolute paths of files/dirs
string[] listDir(string pathname){
	import std.algorithm;
	import std.array;

	return std.file.dirEntries(pathname, SpanMode.shallow)
		.filter!(a => (a.isFile || a.isDir))
		.map!(a => std.path.absolutePath(a.name))
		.array;
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
	immutable size_t lastInd = str.length - 1;
	foreach (i, c; str)
		r |= DIGITS.indexOf(c) << 4 * (lastInd-i);
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
size_t readBinary(string str){
	if (str.length == 0)
		throw new Exception("cannot read binary number from empty string");
	if (str.length > size_t.sizeof * 8)
		throw new Exception("binary number is too big to store in size_t");
	if (!(cast(char[])str).matchElements(['0','1']))
		throw new Exception("invalid character in binary number");
	size_t r;
	immutable size_t lastInd = str.length-1;
	foreach (i, c; str)
		r |= (c == '1') << (lastInd - i);
	return r;
}
/// 
unittest{
	assert("01010101".readBinary == 0B01010101);
}

/// Returns: true if an aray has an element, false if no
bool hasElement(T)(T[] array, T element){
	bool r = false;
	foreach(cur; array){
		if (cur == element){
			r = true;
			break;
		}
	}
	return r;
}
///
unittest{
	assert([0, 1, 2].hasElement(2) == true);
	assert([0, 1, 2].hasElement(4) == false);
}
/// Returns: true if array contains all elements provided in an array, else, false
bool hasElement(T)(T[] array, T[] elements){
	bool r = true;
	elements = elements.dup;
	// go through the list and match as many elements as possible
	for (size_t i = 0; i < elements.length; i ++){
		// check if it exists in array
		size_t index = array.indexOf(elements[i]);
		if (index == -1){
			r = false;
			break;
		}
	}
	return r;
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
bool matchElements(T)(T[] toMatch, T[] elements){
	bool r = true;
	foreach(currentToMatch; toMatch){
		if (!elements.hasElement(currentToMatch)){
			r = false;
			break;
		}
	}
	return r;
}
///
unittest{
	assert("Hello".matchElements("aeloH") == true);
	assert("abcd".matchElements("cda") == false);
}

/// Returns: the index of an element in an array, negative one if not found
ptrdiff_t indexOf(T)(T[] array, T element){
	ptrdiff_t i;
	for (i = 0; i < array.length; i++){
		if (array[i] == element){
			break;
		}
	}
	//check if it was not found, and the loop just ended
	if (i >= array.length || array[i] != element){
		i = -1;
	}
	return i;
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
size_t bracketPos(T, bool forward=true)
(T[] s, size_t index, T[] opening=['[','{','('], T[] closing=[']','}',')']){
	Stack!T brackets = new Stack!T;
	size_t i = index;
	for (immutable size_t lastInd = (forward ? s.length : 0); i != lastInd; (forward ? i ++: i --)){
		if ((forward ? opening : closing).hasElement(s[i])){
			// push it to brackets
			brackets.push(s[i]);
		}else if ((forward ? closing : opening).hasElement(s[i])){
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

/// Removes a number of elements starting from an index
/// 
/// No range checks are done, so an IndexOutOfBounds may occur
///
/// Returns: the modified array
T[] deleteElement(T)(T[] dat, size_t pos, size_t count=1){
	T[] ar1, ar2;
	ar1 = dat[0..pos];
	ar2 = dat[pos+count..dat.length];
	return ar1~ar2;
}
///
unittest{
	assert([0, 1, 2].deleteElement(1) == [0, 2]);
	assert([0, 1, 2].deleteElement(0, 2) == [2]);
}

/// Inserts an array into another array, at a provided index
/// 
/// No range checks are done, so an IndexOutOfBounds may occur
///
/// Returns: the modified array
T[] insertElement(T)(T[] dat, T[] toInsert, size_t pos){
	T[] ar1, ar2;
	ar1 = dat[0..pos];
	ar2 = dat[pos..dat.length];
	return ar1~toInsert~ar2;
}
///
unittest{
	assert([0, 2].insertElement([1, 1], 1) == [0, 1, 1, 2]);
	assert([2].insertElement([0, 1], 0) == [0, 1, 2]);
}
/// Inserts an element into an array
/// 
/// No range checks are done, so an IndexOutOfBounds may occur
///
/// Returns: the modified array
T[] insertElement(T)(T[] dat, T toInsert, size_t pos){
	T[] ar1, ar2;
	ar1 = dat[0..pos];
	ar2 = dat[pos..dat.length];
	return ar1~[toInsert]~ar2;
}
///
unittest{
	assert([0, 2].insertElement(1, 1) == [0, 1, 2]);
	assert([2].insertElement(1, 0) == [1, 2]);
}

/// returns: the reverse of an array
T[] reverseArray(T)(T[] s){
	ptrdiff_t i, writePos = 0;
	T[] r;
	r.length = s.length;

	for (i = s.length-1; writePos < r.length; i--){
		r[writePos] = s[i];
		writePos ++;
	}
	return r;
}
///
unittest{
	assert([1, 2, 3, 4].reverseArray == [4, 3, 2, 1]);
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
T[][] divideArray(T)(T[] array, size_t maxLength){
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

/// Sorts an array, in ascending order, containing floating point, or integers
/// 
/// Returns: true if any sorting was done
bool sortAscending(T)(ref T[] array){
	if (array.length < 2)
		return false;
	bool notSorted;
	bool changed = false;
	immutable size_t lastIndex = array.length-1;
	do{
		notSorted = false;
		for (size_t i = 0; i < lastIndex; i ++){
			if (array[i] > array[i+1]){
				immutable T temp = array[i+1];
				array[i + 1] = array[i];
				array[i] = temp;
				notSorted = true;
			}
		}
		changed = changed || notSorted;
	}while (notSorted);
	return changed;
}
///
unittest{
	int[] array = [0, 2,5,73,2,4,2];
	array.sortAscending;
	assert(array == [0, 2, 2, 2, 4, 5, 73]);
}

/// Sorts an array in ascending order
/// 
/// Returns: array containing indexes of original array's elements in the order they are in now
size_t[] sortAscendingIndex(T)(ref T[] array){
	if (array.length < 2)
		return [0];
	size_t[] indexes;
	indexes.length = array.length;
	foreach (i; 0 .. indexes.length)
		indexes[i] = i;
	bool notSorted;
	immutable size_t lastIndex = array.length-1;
	do{
		notSorted = false;
		for (size_t i = 0; i < lastIndex; i ++){
			if (array[i] > array[i+1]){
				immutable T temp = array[i+1];
				immutable size_t tempIndex = indexes[i+1];
				array[i+1] = array[i];
				indexes[i+1] = indexes[i];
				array[i] = temp;
				indexes[i] = tempIndex;
				notSorted = true;
			}
		}
	}while (notSorted);
	return indexes;
}
///
unittest{
	int[] array = [5,4,9,3,6,2,1];
	size_t[] indexes = array.sortAscendingIndex;
	assert(array == [1,2,3,4,5,6,9]);
	assert(indexes == [6,5,3,1,0,4,2]);
}

/// Returns: true if a string is a number
bool isNum(string s, bool allowDecimalPoint=true){
	bool hasDecimalPoint = false;
	if (!allowDecimalPoint){
		hasDecimalPoint = true; // just a hack that makes it return false on "seeing" decimal point
	}
	s = s.dup;
	if (s.length > 0 && s[0] == '-')
		s = s[1 .. $];
	if (s.length == 0)
		return false;
	foreach (c; s){
		if (c == '.' && !hasDecimalPoint){
			hasDecimalPoint = true;
		}else if (!"0123456789".hasElement(c)){
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
string lowercase(string s){
	static const ubyte diff = 'a' - 'A';
	char[] r = (cast(char[])s).dup;
	foreach (i, c; r){
		if (c >= 'A' && c <= 'Z'){
			r[i] = cast(char)(c+diff);
		}
	}
	return cast(string)r;
}
///
unittest{
	assert("ABcD".lowercase == "abcd");
	assert("abYZ".lowercase == "abyz");
}

/// Returns: true if all characters in a string are alphabets, uppercase, lowercase, or both
bool isAlphabet(string s){
	size_t i;
	bool r=true;
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

/// generates a markdown table for some data.
/// 
/// Arguments:
/// `headings` is the headings for each column. Left-to-Right  
/// `data` contains each row's data. All rows must be same length  
/// 
/// Returns: the markdown, for the table, with each line of markdown as a separate element in the string[]
string[] makeTable(T)(string[] headings, T[][] data){
	assert(headings.length > 0, "cannot make table with no headings");
	assert(data.length > 0, "cannot make table with no data");
	assert(headings.length == data[0].length, "headings.length does not equal data.length "~to!string(headings.length)~"!="~
		to!string(data[0].length));
	import utils.lists;
	// stores the data in string
	string[][] sData;
	// convert it all to string
	static if (is (T == string)){
		sData = data;
	}else{
		sData.length = data.length;
		foreach (rowNum, row; data){
			sData[rowNum].length = row.length;
			foreach (cellNum, cell; row){
				sData[rowNum][cellNum] = to!string(cell);
			}
		}
	}
	// now make the table
	LinkedList!string table = new LinkedList!string;
	// add headings
	{
		string line;
		string alignment;
		line = headings[0];
		alignment = "---";
		for (size_t i = 1; i < headings.length; i ++){
			line ~= " | "~headings[i];
			alignment ~= " | ---";
		}
		table.append([line, alignment]);
	}
	// now begin with the data
	foreach (row; sData){
		string line/* = row[0]*/;
		foreach (cell; row){
			line ~= cell~" | ";
		}
		line.length -= 3;
		table.append (line);
	}
	string[] r = table.toArray;
	.destroy(table);
	return r;
}
