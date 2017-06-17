/++
	This module contains contains some misc. functions. (The name says that)
+/
module utils.misc;

import std.stdio;
import std.datetime;

//These names are easier to understand
///`integer is a `long` on 64 bit systems, and `int` on 32 bit systems
alias integer = ptrdiff_t;
///`uinteger` is a `ulong` on 64 bit systems, and `uint` on 32 bit systems
alias uinteger = size_t;

///Reads a file into an array of string
///Throws exception on failure
string[] fileToArray(string fname){
	try{
		File f = File(fname,"r");
		string[] r;
		string line;
		integer i=0;
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
	}catch (Exception e){
		throw e;
	}
}

/// Writes an array of string to a file
/// Throws exception on failure
void arrayToFile(string fname,string[] array){
	try{
		File f = File(fname,"w");
		uinteger i;
		for (i=0;i<array.length;i++){
			f.write(array[i],'\n');
		}
		f.close;
	}catch (Exception e){
		throw e;
	}
}

/// Returns true if an aray has an element, false if no
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

/// Returns the index of an element in an array, negative one if not found
integer indexOf(T)(T[] array, T element){
	integer i;
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

/// Removes element(s) from an array, and returns the modified array;
T[] deleteElement(T)(T[] dat, uinteger pos, uinteger count=1){
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

/// Inserts an array into another array, returns the result;
T[] insertElement(T)(T[] dat, T[] ins, uinteger pos){
	T[] ar1, ar2;
	ar1 = dat[0..pos];
	ar2 = dat[pos..dat.length];
	return ar1~ins~ar2;
}
///
unittest{
	assert([0, 2].insertElement([1, 1], 1) == [0, 1, 1, 2]);
	assert([2].insertElement([0, 1], 0) == [0, 1, 2]);
}
/// Inserts an element into an array
T[] insertElement(T)(T[] dat, T ins, uinteger pos){
	T[] ar1, ar2;
	ar1 = dat[0..pos];
	ar2 = dat[pos..dat.length];
	return ar1~[ins]~ar2;
}
///
unittest{
	assert([0, 2].insertElement(1, 1) == [0, 1, 2]);
	assert([2].insertElement(1, 0) == [1, 2]);
}

/// returns the reverse of an array
T[] reverseArray(T)(T[] s){
	integer i, writePos = 0;
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

/// Returns a string with all uppercase alphabets converted into lowercase
string lowercase(string s){
	string tmstr;
	ubyte tmbt;
	for (integer i=0;i<s.length;i++){
		tmbt = cast(ubyte) s[i];
		if (tmbt>=65 && tmbt<=90){
			tmbt+=32;
			tmstr ~= cast(char) tmbt;
		}else{
			tmstr ~= s[i];
		}
	}
	
	return tmstr;
}
///
unittest{
	assert("ABcD".lowercase == "abcd");
}

/// returns true if all characters in a string are alphabets, uppercase, lowercase, or both
bool isAlphabet(string s){
	s = lowercase(s);
	uinteger i;
	bool r=true;
	ubyte chCode;
	for (i=0;i<s.length;i++){
		chCode = cast(ubyte)s[i];
		if (chCode<97 || chCode>122){r=false;break;}
	}
	return r;
}
///
unittest{
	assert("aBcDEf".isAlphabet == true);
	assert("ABCd_".isAlphabet == false);
}