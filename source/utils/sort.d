module utils.sort;

import std.algorithm;
import std.functional;
import std.traits;
debug import std.conv : to;

/// Sort an input array, where only [0 .. count] elements are required
/// **THIS WILL MODIFY `input` ARRAY**
///
/// Returns: sorted [0 .. count] elements
T[] partialSort(alias val = "a", T)(T[] input, ulong count){
	T[] selection = radixSort!val(input[0 .. count]);
	T[] temp;
	temp.length = count;
	T cmp = selection[$ - 1];

	input = input[count .. $];
	ulong i;
	foreach (num; input){
		if (num < cmp){
			temp[i ++] = num;
			if (i == temp.length){
				selection = mergeEq!val(selection, radixSort!val(temp));
				i = 0;
				cmp = selection[$ - 1];
			}
		}
	}
	if (i)
		selection = merge!val(selection, radixSort!val(temp[0 .. i]), count);
	return selection;
}
///
unittest{
	uint[] input = [7, 0, 5, 4, 6, 8, 9];
	assert(partialSort(input, 1) == [0]);
	assert(partialSort(input, 2) == [0, 4]);
	assert(partialSort(input, 3) == [0, 4, 5]);
	assert(partialSort(input, 4) == [0, 4, 5, 6]);
}

/// Radix sort. ascending order.
/// The input array is sorted after by this, and the ptr can be modified too
/// the sorted array is returned as well
///
/// Returns: sorted array
T[] radixSort(alias val = "a", T)(ref T[] input){
	alias valGet = unaryFun!val;
	enum ubyte end = typeof(valGet(input[0])).sizeof * 8;
	size_t[256] counts;
	T[] output = new T[input.length];
	for (ubyte i = 0; i < end; i += 8){
		counts[] = 0;
		foreach (val; input)
			++ counts[(valGet(val) >> i) & 255];
		foreach (j; 1 .. counts.length)
			counts[j] += counts[j - 1];
		foreach_reverse (val; input)
			output[-- counts[(valGet(val) >> i) & 255]] = val;
		swap(input, output);
	}
	return input;
}
///
unittest{
	uint[] input = [7, 0, 5, 4, 6, 8, 9];
	assert(radixSort(input) == [0, 4, 5, 6, 7, 8, 9]);
}

/// merge sort
T[] mergeSort(alias val = "a", T)(T[] arr, ulong maxLen = 0){
	alias valGet = unaryFun!val;
	if (arr.length == 1){
		return arr;
	}
	if (arr.length == 2){
		if (valGet(arr[0]) < valGet(arr[1]))
			return arr;
		return [arr[1], arr[0]];
	}
	ulong mid = (arr.length + 1) / 2;
	return merge!val(mergeSort!val(arr[0 .. mid], maxLen),
					mergeSort!val(arr[mid .. $], maxLen),
					maxLen);
}
///
unittest{
	uint[] input = [7, 0, 5, 4, 6, 8, 9];
	assert(mergeSort(input) == [0, 4, 5, 6, 7, 8, 9]);
}

/// Merge 2 sorted arrays of same length, into a third array, of same length.
/// i.e, half the elements are discarded.
T[] mergeEq(alias val = "a", T)(T[] A, T[] B){
	assert(A.length == B.length, "mergeEq called on arrays of not equal lengths");
	alias valGet = unaryFun!val;
	T[] R;
	R.length = A.length;
	for (size_t i, a, b; i < R.length; i ++)
		R[i] = valGet(A[a]) < valGet(B[b]) ? A[a ++] : B[b ++];
	return R;
}
///
unittest{
	uint[] A = [0, 5, 7]; // sorted array
	uint[] B = [4, 6, 8]; // also sorted
	assert(mergeEq(A, B) == [0, 4, 5]);
}

/// Merge 2 sorted arrays.
///
/// if maxLen is non zero, only first maxLen number of elements are returned.
/// using maxLen should give slight performance benefit
T[] merge(alias val = "a", T)(T[] A, T[] B, size_t maxLen = 0){
	alias valGet = unaryFun!val;
	T[] R;
	R.length = maxLen && maxLen < A.length + B.length ? maxLen : A.length + B.length;

	size_t a, b, i;
	if (A.length && B.length){
		while (i < R.length){
			if (valGet(A[a]) < valGet(B[b])){
				R[i ++] = A[a ++];
				if (a == A.length)
					break;
			}else{
				R[i ++] = B[b ++];
				if (b == B.length)
					break;
			}
		}
	}
	if (a < A.length){
		R[i .. $] = A[a .. a + R.length - i];
	}else if (b < B.length){
		R[i .. $] = B[b .. b + R.length - i];
	}
	return R;
}
///
unittest{
	uint[] A = [0, 5, 7]; // sorted array
	uint[] B = [4, 6, 8, 9]; // also sorted, not same length
	assert(merge(A, B) == [0, 4, 5, 6, 7, 8, 9]);
	assert(merge(A, B, 4) == [0, 4, 5, 6]);
}
