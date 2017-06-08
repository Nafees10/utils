/++
	This module contains functions for converting between different number bases.  
	Like converting to/from hex...
+/
module utils.baseconv;

import std.math;

private size_t toDenary(ushort fromBase, ubyte[] dat){
	size_t r = 0, i = 0;
	foreach_reverse(cur; dat){
		r += pow(fromBase,i)*cur;
		i++;
	}
	return r;
}
///
unittest{
	assert(toDenary(2, [1, 0, 0, 1]) == 9);
}

private ubyte[] fromDenary(ushort toBase, size_t dat){
	ubyte rem;
	ubyte[] r;
	while (dat>0){
		rem = cast(ubyte)dat%toBase;
		dat = (dat-rem)/toBase;
		r = [rem]~r;
	}
	
	return r;
}
///
unittest{
	assert(fromDenary(2, 9) == [1, 0, 0, 1]);
}

private string toFormat(ubyte[] ar, char[] rep){
	size_t i;
	char[] r;
	r.length = ar.length;
	for (i=0; i<ar.length; i++){
		r[i] = rep[ar[i]];
	}
	return cast(string)r;
}
///
unittest{
	assert([1, 0, 0, 1].toFormat(['0', '1']) == "1001");
}

private ubyte[] fromFormat(string ar, char[] rep){
	size_t i;
	ubyte[] r;
	r.length = ar.length;
	for (i=0; i<ar.length; i++){
		r[i] = cast(ubyte)strSearch(cast(string)rep, ar[i]);
	}
	return r;
}
///
unittest{
	assert("1001".fromFormat(['0', '1']) == [1, 0, 0, 1]);
}

private size_t strSearch(string s, char ss){
	size_t i;
	for (i=0; i<s.length; i++){
		if (s[i]==ss){
			break;
		}
	}
	if (i>=s.length){
		i = -1;
	}
	return i;
}
//exported functions:

/// To 'encode' an unsigned integer into anarray of char
char[] denaryToChar(size_t den){
	return cast(char[])fromDenary(256,den);
}
///
unittest{
	assert(255.denaryToChar == cast(char[])[255]);
}

/// To decode 'stream of char' into unsigned integer
size_t charToDenary(char[] ch){
	return toDenary(256,cast(ubyte[])ch);
}
///
unittest{
	assert(charToDenary(cast(char[])[255]) == 255);
}

/// Converts a hex from string into unsigned integer
size_t hexToDenary(string hex){
	ubyte[] buffer;
	buffer = fromFormat(hex,cast(char[])"0123456789ABCDEF");
	return toDenary(16,buffer);
}
///
unittest{
	assert("A1".hexToDenary == 161);
}

/// Converts unsigned integer into hex
string denaryToHex(size_t den){
	ubyte[] buffer;
	return toFormat(fromDenary(16,den),cast(char[])"0123456789ABCDEF");
}
///
unittest{
	assert(162.denaryToHex == "A2");
}

/// Converts a binary number from string into denary
size_t binaryToDenary(string bin){
	ubyte[] buffer;
	buffer = fromFormat(bin, cast(char[])"01");
	return toDenary(2, buffer);
}
///
unittest{
	assert("1001".binaryToDenary == 9);
}

/// Converts a denary number into a binary number in string
string denaryToBinary(size_t den){
	ubyte[] buffer;
	return toFormat(fromDenary(2,den),cast(char[])"01");
}
///
unittest{
	assert(9.denaryToBinary == "1001");
}