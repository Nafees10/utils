/++
	This module contains functions for converting between different number bases.  
	Like converting to/from hex...
+/
module utils.baseconv;

import utils.misc;
import std.math;

uinteger toDenary(ushort fromBase, ubyte[] dat){
	uinteger r = 0, i = 0;
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

ubyte[] fromDenary(ushort toBase, uinteger dat){
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
	uinteger i;
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
	uinteger i;
	ubyte[] r;
	r.length = ar.length;
	for (i=0; i<ar.length; i++){
		r[i] = cast(ubyte)rep.indexOf(ar[i]);
	}
	return r;
}
///
unittest{
	assert("1001".fromFormat(['0', '1']) == [1, 0, 0, 1]);
}
//exported functions:

/// Converts from denary to another base
/// 
/// denaryNumber is the denary to convert
/// newBaseDigits are the digits of the new base in the ascending order, for hex, this will be `cast(char[])"0123456789ABCDEF"`
/// newbaseDigits must have at least 2 digits
string denaryToBase(uinteger denaryNumber, char[] newBaseDigits){
	assert(newBaseDigits.length >= 2);
	return toFormat(fromDenary(cast(ushort)newBaseDigits.length, denaryNumber), newBaseDigits);
}
///
unittest{
	assert(denaryToBase(161,cast(char[])"0123456789ABCDEF") == "A1");
}

/// Converts from any base to denary using the digits of the provided base
/// 
/// baseNumber is the number in another base to convert to denary
/// baseDigits is the digits of the base to convert from, in asennding order
uinteger baseToDenary(string baseNumber, char[] baseDigits){
	assert(baseDigits.length >= 2);
	return toDenary(cast(ushort)baseDigits.length, fromFormat(baseNumber, baseDigits));
}
///
unittest{
	assert(baseToDenary("A1", cast(char[])"0123456789ABCDEF") == 161);
}

/// To 'encode' an unsigned integer into anarray of char
char[] denaryToChar(uinteger den){
	return cast(char[])fromDenary(256,den);
}
///
unittest{
	assert(255.denaryToChar == cast(char[])[255]);
}

/// To decode 'stream of char' into unsigned integer
uinteger charToDenary(char[] ch){
	return toDenary(256,cast(ubyte[])ch);
}
///
unittest{
	assert(charToDenary(cast(char[])[255]) == 255);
}

/// Converts a hex from string into unsigned integer
uinteger hexToDenary(string hex){
	return baseToDenary(hex, cast(char[])"0123456789ABCDEF");
}
///
unittest{
	assert("A1".hexToDenary == 161);
}

/// Converts unsigned integer into hex
string denaryToHex(uinteger den){
	return denaryToBase(den, cast(char[])"0123456789ABCDEF");
}
///
unittest{
	assert(162.denaryToHex == "A2");
}

/// Converts a binary number from string into denary
uinteger binaryToDenary(string bin){
	return baseToDenary(bin, ['0', '1']);
}
///
unittest{
	assert("1001".binaryToDenary == 9);
}

/// Converts a denary number into a binary number in string
string denaryToBinary(uinteger den){
	return denaryToBase(den, ['0', '1']);
}
///
unittest{
	assert(9.denaryToBinary == "1001");
}
