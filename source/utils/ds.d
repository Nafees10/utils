/++
	Some data structures
+/
module utils.ds;
import utils.misc;

import std.file,
			 std.meta,
			 std.conv,
			 std.stdio,
			 std.traits,
			 std.bitmanip,
			 std.algorithm;

/// Used to read some data type as `ubyte[x]`
union ByteUnion(T){
	T data; /// data
	ubyte[T.sizeof] array; /// array of bytes
	/// constructor
	this(T data){
		this.data = data;
	}
	/// ditto
	this(ubyte[T.sizeof] array){
		this.array = array;
	}
}

/++
Set of type `T`

Uses an associative array with element type `void[0]` under the hood
(`Set.set`)

Following operator overloads are present:

* `a + b` - Set union
* `a - b` - Set difference
* `a += b` - Add all keys of b to a
* `a -= b` - Remove all keys from a, that exist in both a and b
+/
struct Set(T){
	/// The assoc_array being used as Set
	void[0][T] set;
	alias set this;

	this(T[] vals){
		put(vals);
	}

	/// Add to set
	void put(T val) pure {
		set[val] = (void[0]).init;
	}
	/// ditto
	void put(T[] vals) pure {
		foreach (val; vals)
			put(val);
	}

	/// Returns: whether `val` exists in Set
	bool exists(T val) pure const {
		return (val in set) !is null;
	}

	/// Returns: whether this contains all the elements as `rhs`, and vice versa
	bool opEquals(const Set!T rhs) pure const {
		if (rhs.set.keys.length != set.keys.length)
			return false;
		foreach (key; set.keys){
			if (!rhs.exists(key))
				return false;
		}
		return true;
	}

	/// Returns: new Set, with set union
	Set!T opBinary(string op : "+")(const Set!T rhs) pure const {
		Set!T ret;
		ret.put(keys);
		ret.put(rhs.keys);
		return ret;
	}

	/// Returns: new Set, with set differnce
	Set!T opBinary(string op : "-")(const Set!T rhs) pure const {
		Set!T ret;
		foreach (key; set.keys.filter!(k => !rhs.exists(k)))
			ret.put(key);
		return ret;
	}

	ref Set!T opOpAssign(string op : "+")(const Set!T rhs) pure {
		foreach (key; rhs.keys)
			put(key);
		return this;
	}

	ref Set!T opOpAssign(string op : "-")(const Set!T rhs) pure {
		foreach (key; rhs.keys)
			remove(key);
		return this;
	}
}
///
unittest{
	Set!int set;
	foreach (i; 0 .. 5)
		set.put(i);
	foreach (i; 0 .. 5)
		assert(set.exists(i));
	assert(!set.exists(-1));
	assert(!set.exists(5));

	Set!int second = Set!int([1, 2, 3]);
	assert(set - second == Set!int([0, 4]));
	assert (second - set == Set!int());
}

/++
Stores bit flags against each enum member, and provides overloaded bitwise
operators

Usage:
```
	flag[Val] = true;
	flag += Val; // same as above
	flag -= Val; // store false against Val
	flag.set!Val(false); // same as above
	flag.set(Val, false); // same as above
```

Following operators are overloaded:

* `flags & flags`
* `flags & Val` - RHS is treated as flags with only Val as true
* `flags | flags`
* `flags | Val` - RHS is treated as flags with only Val as true
* `flags ^ flags`
* `flags ^ Val` - RHS is treated as flags with only Val as true
* assignment operator with these (`&= |= ^=`)
* `flags[Val]` - to read
* `flags[Val] = bool`
* `flags[Val] |= bool`
* `flags[Val] &= bool`
* `flags[Val] ^= bool`
* `flags == otherFlags`
* `flags != otherFlags`
* `flags == Val` - Check if bit against Val is 1
* `flags = bool` - Set value of all flags
* `cast(bool)flags` - true if any one bit is 1
+/
struct Flags(T) if (is(T == enum)){
private:
	/// flags byte array
	ubyte[(EnumMembers!T.length  + 7) / 8] _flags;

	/// index in _flags for a enum member
	enum _index(T val) =
		[EnumMembers!T].indexOf(val) >= 0
		? [EnumMembers!T].indexOf(val) / 8 : -1;

	/// shift value for enum member
	enum _shift(T val) = [EnumMembers!T].indexOf(val) - (_index!val * 8);

	/// Error message for when a value is not enum member
	enum _notMemberError(T val) = val.to!string ~
		" is not a member of enum " ~ T.stringof;

	enum _isValidType(V) = is(V == T);

	/// Returns: [index, shift]. index can be -1 to indicate not existing
	size_t[2] _getIndexShift(T val) const {
		immutable ptrdiff_t index = [EnumMembers!T].indexOf(val);
		if (index < 0)
			return [-1, -1];
		immutable size_t acInd = index / 8;
		return [acInd, index - (acInd * 8)];
	}

	/// private constructor
	this(ubyte[(EnumMembers!T.length + 7) / 8] flags){
		_flags[] = flags;
		// fix last byte, set unused to 0
		static if (EnumMembers!T.length % 8)
			_flags[$ - 1] &= (1 << (EnumMembers!T.length % 8)) - 1;
	}

public:
	this(V...)(V initial) if (allSatisfy!(_isValidType, V)){
		foreach (val; initial)
			set(val);
	}

	/// Returns: number of flags that match a value
	size_t count(bool value = true){
		// count 1s
		size_t ones;
		static foreach(i; 0 .. _flags.length){
			static foreach(shift; 0 .. 8)
				ones += (_flags[i] >> shift) & 1;
		}
		if (value)
			return ones;
		return EnumMembers!T.length - ones;
	}

	/// Returns: boolean value against an enum member
	bool get(T val)() const {
		static assert(_index!val >= 0, _notMemberError!val);
		return (_flags[_index!val] >> _shift!val) & 1;
	}

	/// will return false in case member not existing
	bool get(T val) const {
		size_t[2] indShift = _getIndexShift(val);
		if (indShift[0] == -1)
			return false;
		return (_flags[indShift[0]] >> indShift[1]) & 1;
	}

	/// Sets boolean value against an enum member
	void set(T val)(bool flag = true){
		static assert(_index!val >= 0, _notMemberError!val);
		_flags[_index!val] = (_flags[_index!val] & ~(1 << _shift!val)) |
			(flag << _shift!val);
	}

	/// will do nothing in case member not existing
	void set(T val, bool flag = true){
		size_t[2] indShift = _getIndexShift(val);
		if (indShift[0] == -1)
			return;
		_flags[indShift[0]] = cast(ubyte)(
			(_flags[indShift[0]] & ~(1 << indShift[1])) |
			(flag << indShift[1]));
	}

	/// Sets all flags
	void set(bool flag = true){
		this = flag;
	}

	/// index assign operator
	ref Flags!T opIndexAssign(bool val, T index){
		set(index, val);
		return this;
	}

	/// index operator
	bool opIndex(T index) const {
		return get(index);
	}

	/// index `&=` operator
	bool opIndexOpAssign(string op : "&")(bool val, T index){
		size_t[2] indShift = _getIndexShift(index);
		if (indShift[0] == -1)
			return false;
		set(index, get(index) && val);
		return get(index);
	}

	/// index `|=` operator
	bool opIndexOpAssign(string op : "|")(bool val, T index){
		size_t[2] indShift = _getIndexShift(index);
		if (indShift[0] == -1)
			return false;
		set(index, get(index) || val);
		return get(index);
	}

	/// index `^=` operator
	bool opIndexOpAssign(string op : "^")(bool val, T index){
		size_t[2] indShift = _getIndexShift(index);
		if (indShift[0] == -1)
			return false;
		set(index, get(index) ^ val);
		return get(index);
	}

	/// assign operator for bool, sets all flags
	ref Flags!T opAssign(bool rhs){
		_flags[] = ubyte.max * rhs;
		// fix the last byte. unused bits should be all 0
		static if (EnumMembers!T.length % 8)
			_flags[$ - 1] &= (1 << (EnumMembers!T.length % 8)) - 1;
		return this;
	}

	/// `+=` operator, sets a flag to true
	ref Flags!T opOpAssign(string op : "+")(T rhs){
		set(rhs, true);
		return this;
	}

	/// `-=` operator, sets a flag to false
	ref Flags!T opOpAssign(string op : "-")(T rhs){
		set(rhs, false);
		return this;
	}

	/// `==` operator
	bool opBinary(string op : "==")(const ref Flags!T rhs) const {
		static if (EnumMembers!T.length % 8 == 0)
			return _flags == rhs._flags;
		if (_flags[0 .. $ - 1] != rhs._flags[0 .. $ - 1])
			return false;
		enum ubyte shift = 8 - (EnumMembers!T.length % 8);
		return (_flags[$ - 1] << shift) == (rhs._flags[$ - 1] << shift);
	}

	/// ditto
	bool opBinary(string op : "==")(T rhs) const {
		return get(rhs);
	}

	/// `!=` operator
	bool opBinary(string op : "!=")(const ref Flags!T rhs) const {
		return !(this == rhs);
	}

	/// ditto
	bool opBinary(string op : "!=")(T rhs) const {
		return !(this == rhs);
	}

	/// `&=` operator
	ref Flags!T opOpAssign(string op : "&")(const ref Flags!T rhs){
		static foreach (i; 0 .. _flags.length)
			_flags[i] &= rhs._flags[i];
		return this;
	}

	/// ditto
	ref Flags!T opOpAssign(string op : "&")(T rhs){
		size_t[2] indShift = _getIndexShift(rhs);
		if (indShift[0] == -1)
			return this;
		ubyte slice = _flags[indShift[0]];
		_flags[] = 0;
		_flags[indShift[0]] = slice & (1 << indShift[1]);
		return this;
	}

	/// `&` operator
	Flags!T opBinary(string op : "&")(const ref Flags!T rhs) const {
		Flags!T ret = Flags!T(_flags);
		ret &= rhs;
		return ret;
	}

	/// ditto
	Flags!T opBinary(string op : "&")(T rhs) const {
		Flags!T ret = Flags!T(_flags);
		ret &= rhs;
		return ret;
	}

	/// `|=` operator
	ref Flags!T opOpAssign(string op : "|")(const ref Flags!T rhs){
		static foreach (i; 0 .. _flags.length)
			_flags[i] |= rhs._flags[i];
		return this;
	}

	/// ditto
	ref Flags!T opOpAssign(string op : "|")(T rhs){
		size_t[2] indShift = _getIndexShift(rhs);
		if (indShift[0] == -1)
			return this;
		_flags[indShift[0]] |= 1 << indShift[1];
		return this;
	}

	/// `|` operator
	Flags!T opBinary(string op : "|")(const ref Flags!T rhs) const {
		Flags!T ret = Flags!T(_flags);
		ret |= rhs;
		return ret;
	}

	/// ditto
	Flags!T opBinary(string op : "|")(T rhs) const {
		Flags!T ret = Flags!T(_flags);
		ret |= rhs;
		return ret;
	}

	/// `^=` operator
	ref Flags!T opOpAssign(string op : "^")(const ref Flags!T rhs){
		static foreach(i; 0 .. _flags.length)
			_flags[i] ^= rhs._flags[i];
		return this;
	}

	/// ditto
	ref Flags!T opOpAssign(string op : "^")(T rhs){
		size_t[2] indShift = _getIndexShift(rhs);
		if (indShift[0] == -1)
			return this;
		_flags[indShift[0]] = cast(ubyte)(
				(_flags[indShift[0]] & ~(1 << indShift[1])) | // 0 that bit
				(_flags[indShift[0]] ^ (1 << indShift[1]) & (1 << indShift[1]))
				);
		return this;
	}

	/// `^` operator
	Flags!T opBinary(string op : "^")(const ref Flags!T rhs) const {
		Flags!T ret = Flags!T(_flags);
		ret ^= rhs;
		return ret;
	}

	/// ditto
	Flags!T opBinary(string op : "^")(T rhs) const {
		Flags!T ret = Flags!T(_flags);
		ret ^= rhs;
		return ret;
	}

	/// cast to bool (true if at least 1 flag true)
	bool opCast(TT : bool)() const {
		foreach (flags; _flags){
			if (flags)
				return true;
		}
		return false;
	}
}
///
unittest{
	enum EventType{
		Update,
		KeyPress,
		KeyRelease,
		MousePress,
		MouseRelease,
		MouseHover,
		Resize,
		Timer,
		Init
	}

	Flags!EventType eventSub;
	// initially, all should be false
	foreach (val; EnumMembers!EventType){
		assert(eventSub.get!val == false);
		assert(eventSub.get(val) == false);
	}
	assert(eventSub.count == 0);
	assert(eventSub.count(false) == EnumMembers!EventType.length);
	// test that constructor
	eventSub = Flags!EventType(EventType.Update, EventType.Timer);
	assert(eventSub.count == 2, eventSub.count.to!string);
	assert(eventSub.get!(EventType.Update) && eventSub.get!(EventType.Timer));
	eventSub = Flags!EventType();
	// set even numbered to true, check if it worked
	foreach (i, val; EnumMembers!EventType){
		eventSub.set!val(i % 2 == 0);
		assert (eventSub.get!val == (i % 2 == 0));
	}
	eventSub.set(false);
	foreach (i, val; EnumMembers!EventType){
		eventSub.set(val, i % 2 == 0);
		assert (eventSub.get(val) == (i % 2 == 0));
	}
	// set all to true
	eventSub.set(true);
	foreach (val; EnumMembers!EventType){
		assert(eventSub.get!val == true);
		assert(eventSub.get(val) == true);
	}
	// set all to false
	eventSub.set(false);
	foreach (val; EnumMembers!EventType){
		assert(eventSub.get!val == false);
		assert(eventSub.get(val) == false);
	}

	// time for comparison operators
	Flags!EventType eSub;
	assert(eventSub == eSub);
	eventSub.set(true);
	assert(eventSub != eSub);
	eSub.set(true);
	assert(eventSub == eSub);
	eventSub.set(false);
	assert(eventSub != eSub);

	eSub.set(false);
	foreach (i, val; EnumMembers!EventType){
		eventSub.set!val(i % 2 == 0);
		eSub.set!val(i % 2 == 1);
	}
	assert(eventSub != eSub);
	foreach (i, val; EnumMembers!EventType){
		eSub.set!val(i % 2 == 0);
	}
	assert(eventSub == eSub);

	// bool cast
	assert(eSub);
	assert(eventSub);
	eSub.set(false);
	assert(!eSub);
	eSub.set!(EventType.Init)(true);
	assert(eSub);
	eventSub.set(true);
	foreach (val; EnumMembers!EventType)
		eventSub.set!val(false);
	assert(!eventSub);

	// testing bitwise operators
	// bitwise and:
	eSub.set(false);
	eventSub.set(false);
	eSub.set!(EventType.KeyPress)(true);
	eSub.set!(EventType.KeyRelease)(true);
	eventSub.set(true);
	// anding both should give key press and release
	assert((eSub & eventSub) == eSub);
	assert ((eSub | EventType.KeyPress | EventType.KeyRelease) == eSub);
	eventSub.set!(EventType.KeyPress)(false);
	// now resulting Flags should only have key release
	assert((eSub & eventSub).get!(EventType.KeyRelease) == true);
	assert((eSub & eventSub).count == 1);
	assert((eSub & EventType.KeyRelease).get!(EventType.KeyRelease) == true);
	assert((eSub & EventType.KeyRelease).count(true) == 1);
	// bitwise or
	eSub.set(true);
	eSub.set!(EventType.Init)(false);
	eventSub.set(false);
	eventSub.set!(EventType.Init)(true);
	assert ((eventSub | eSub).count(true) == 9);
	assert ((eventSub | EventType.MouseHover).get!(EventType.MouseHover));
	assert ((eventSub | EventType.MouseHover).count(true) == 2);
	assert ((eventSub | EventType.MouseHover | EventType.MouseRelease).
		count(true) == 3);
	assert ((eventSub | EventType.MouseHover | EventType.MouseRelease).
		get!(EventType.MouseRelease) == true);
	// bitwise xor
	assert((eventSub ^ eSub).count(true) == 9);
	eventSub.set(true);
	eSub.set(true);
	assert((eventSub ^ eSub).count(true) == 0);
	assert ((eventSub ^ EventType.Init).get!(EventType.Init) == false);
	assert ((eventSub ^ EventType.Init).count(true) == 8);

	/// testing overloaded operators
	eventSub = false;
	assert(eventSub.count(true) == 0);
	eSub = true;
	assert(eSub.count(true) == EnumMembers!EventType.length);
	assert(eventSub[EventType.Resize] == false);
	eventSub[EventType.Resize] = true;
	assert(eventSub[EventType.Resize] == true);
	assert(eventSub[EventType.Init] == false);
	eventSub += EventType.Init;
	assert(eventSub[EventType.Init] == true);
	eventSub -= EventType.Init;
	assert(eventSub[EventType.Init] == false);
	eventSub[EventType.Timer] |= false;
	assert(eventSub[EventType.Timer] == false);
	eventSub[EventType.Timer] |= true;
	assert(eventSub[EventType.Timer] == true);
	eventSub[EventType.Timer] |= false;
	assert(eventSub[EventType.Timer] == true);
	eventSub[EventType.Update] ^= false;
	assert(eventSub[EventType.Update] == false);
	eventSub[EventType.Update] ^= true;
	assert(eventSub[EventType.Update] == true);
	eventSub[EventType.Update] &= true;
	assert(eventSub[EventType.Update] == true);
	eventSub[EventType.Update] &= false;
	assert(eventSub[EventType.Update] == false);
}

/// A linked list based stack with push, and pop
class Stack(T){
private:
	struct Item(T){
		T data; /// the data this item holds
		Item* prev; /// pointer to previous Item
		/// constructor
		this(T data){
			this.data = data;
		}
		/// ditto
		this(T data, Item* prev){
			this.data = data;
			this.prev = prev;
		}
	}
	Item!(T)* _top;
	size_t _count;
public:
	this(){
		_top = null;
		_count = 0;
	}
	~this(){
		clear;
	}
	/// Appends an item to the stack
	void push(T item){
		Item!(T)* newItem = new Item!T(item, _top);
		_top = newItem;
		_count ++;
	}
	/// Appends an array of items to the stack
	void push(T[] items){
		foreach (item; items)
			push(item);
	}
	/// peeks an item on stack
	///
	/// Returns: item peeked
	///
	/// Throws: Exception if stack is empty
	T peek(){
		if (_top is null)
			throw new Exception("Cannot peek from empty stack");
		return _top.data;
	}
	/// pops an item from stack
	///
	/// Returns: the item poped
	///
	/// Throws: Exception if stack is empty
	T pop(){
		if (_top is null)
			throw new Exception("Cannot pop from empty stack");
		T ret = _top.data;
		Item!(T)* prev = _top.prev;
		.destroy(_top);
		_top = prev;
		//decrease count
		_count --;
		return ret;
	}
	/// Reads and removes an array of items from the stack,
	///
	/// Throws: Exception if there are not enough items in stack
	///
	/// Arguments:
	/// `arr` is the array to fill. it's length is number of elements to pop
	/// `reverse`, whether to populate array in reverse (top in stack, at last)
	void pop(bool reverse=false)(T[] arr){
		//make sure there are enough items
		if (_count < arr.length)
			throw new Exception("Not enough items in stack");
		Item!(T)* ptr = _top;
		static if (reverse){
			foreach_reverse (ref element; arr){
				element = ptr.data;
				ptr = ptr.prev;
				.destroy(_top);
				_top = ptr;
			}
		}else{
			foreach (ref element; arr){
				element = ptr.data;
				ptr = ptr.prev;
				.destroy(_top);
				_top = ptr;
			}
		}
		//decrease count
		_count -= arr.length;
	}
	/// Empties the stack, pops all items
	void clear(){
		// go through all items and delete em
		Item!(T)* ptr;
		ptr = _top;
		while (ptr !is null){
			Item!(T)* prevPtr = ptr.prev;
			destroy(ptr);
			ptr = prevPtr;
		}
		_top = null;
		_count = 0;
	}
	/// Number of items in stack
	@property size_t count(){
		return _count;
	}
}
///
unittest{
	Stack!ubyte stack = new Stack!ubyte;
	//`Stack.push` and `Stack.pop`
	stack.push(0);
	stack.push([1, 2]);
	assert(stack.pop == 2);
	ubyte[] arr;
	arr.length = 2;
	stack.pop(arr);
	assert(arr == [1, 0]);
	stack.push([1, 0]);
	stack.pop!true(arr);
	assert(arr == [1, 0]);
	//`Stack.clear` && `Stack.count`
	stack.push(0);
	assert(stack.count == 1);
	stack.clear;
	assert(stack.count == 0);
	stack.destroy;
}

/// A First-In First-Out stack
class FIFOStack(T){ // TODO refactor this
private:
	/// to store data in a linked manner
	struct StackElement(T){
		T data; /// the data stored
		StackElement!(T)* next = null; /// pointer to data which was pushed after it
	}
	/// pointer to first item (first pushed, the one to pop next)
	StackElement!(T)* firstItemPtr;
	/// pointer to last item (last pushed)
	StackElement!(T)* lastItemPtr;
	/// stores number of elements pushed
	size_t _count;
public:
	/// constructor
	this (){
		firstItemPtr = null;
		lastItemPtr = null;
		_count = 0;
	}
	/// destructor
	~this (){
		// clear the whole stack
		clear;
	}
	/// clears the whole stack, pops all items
	void clear(){
		for (StackElement!(T)* i = firstItemPtr, next = null; i !is null; i = next){
			next = (*i).next;
			.destroy(*i);
		}
		_count = 0;
	}
	/// Returns: number of items in stack
	@property size_t count(){
		return _count;
	}
	/// pushes an element to stack
	void push(T element){
		StackElement!(T)* toPush = new StackElement!(T);
		(*toPush).data = element;
		(*toPush).next = null;
		// check if stack is empty
		if (lastItemPtr is null){
			firstItemPtr = toPush;
		}else{
			(*lastItemPtr).next = toPush;
		}
		lastItemPtr = toPush;
		_count ++;
	}
	/// pushes an array of elements to stack
	void push(T[] elements){
		StackElement!(T)*[] toPush;
		toPush.length = elements.length;
		if (toPush.length > 0){
			// make a linked stack for just these elements first
			foreach (i, element; elements){
				toPush[i] = new StackElement!(T);
				(*toPush[i]).data = element;
				if (i > 0){
					(*toPush[i-1]).next = toPush[i];
				}
			}
			(*toPush[$ - 1]).next = null;
			// now "insert" it
			if (lastItemPtr is null){
				firstItemPtr = toPush[0];
			}else{
				(*lastItemPtr).next = toPush[0];
			}
			lastItemPtr = toPush[$ - 1];
			_count += elements.length;
		}
	}
	/// pops an item from the stack (from bottom of stack, since it's a FIFO stack)
	///
	/// Returns: the element pop-ed
	///
	/// Throws: Exception if the stack is empty
	T pop(){
		if (firstItemPtr is null){
			throw new Exception("Cannot pop from empty stack");
		}
		T r = (*firstItemPtr).data;
		StackElement!(T)* toDestroy = firstItemPtr;
		firstItemPtr = (*firstItemPtr).next;
		.destroy(toDestroy);
		_count --;
		// check if list is now empty
		if (firstItemPtr is null){
			lastItemPtr = null;
		}
		return r;
	}
	/// pops a number of items from the stack (from bottom since it's a FIFO Stack)
	///
	/// If there aren't enoguh items in stack, all the items are poped, and the returned array's length is less than `popCount`
	///
	/// Returns: the elements poped
	///
	/// Throws: Exception if stack is empty
	T[] pop(size_t popCount){
		if (count == 0){
			throw new Exception("Cannot pop from empty stack");
		}
		if (_count < popCount){
			popCount = _count;
		}
		size_t i = 0;
		StackElement!(T)* item = firstItemPtr;
		T[] r;
		r.length = popCount;
		while (i < popCount && item !is null){
			StackElement!(T)* toDestroy = item;
			r[i] = (*item).data;
			item = (*item).next;
			.destroy(toDestroy);
			i ++;
		}
		firstItemPtr = item;
		_count -= popCount;
		// check if list is empty now
		if (firstItemPtr is null){
			lastItemPtr = null;
		}
		return r;
	}
}

///
unittest{
	FIFOStack!int stack = new FIFOStack!int;
	stack.push(0);
	stack.push([1,2,3,4]);
	assert(stack.count == 5);
	assert(stack.pop == 0);
	assert(stack.count == 4);
	assert(stack.pop(2) == [1,2]);
	assert(stack.count == 2);
	assert(stack.pop(2) == [3,4]);
	assert(stack.count == 0);
	stack.push([0,1,2]);
	assert(stack.count == 3);
	assert(stack.pop(3) == [0,1,2]);
}

// TODO: do something about this
/// **NOT IMPLEMENTED YET**
/// For reading large files which otherwise, would take too much memory
///
/// Aside from reading, it can also write to files.
deprecated abstract class FileReader{}/*
private:
	File file; /// the file currently loaded
	bool closeOnDestroy; /// stores if the file will be closed when this object is destroyed
	size_t _minSeek; /// stores the minimum value of seek, if zero, it has no effect
	size_t _maxSeek; /// stores the maximum value of seek, if zero, it has no effect
	size_t _maxSize; /// stores the max size of the file in case _minSeek and _maxSeek are set non-zero
	string _filename; /// the filename of the file opened
public:
	/// prepares a file for reading/writing through this class
	///
	/// if filename does not exists, attempts to create it
	///
	/// Throws: Exception (ErrnoException) if some error occurs
	this(string filename){
		file = File (filename, filename.exists ? "r+" : "w+");
		closeOnDestroy = true;
		_filename = filename;
		_minSeek = 0;
		_maxSeek = 0;
	}
	/// prepares this object for reading/writing an already opened file
	///
	/// When this constructor is used, file will not be closed when this object is destroyed
	/// and keep in mind that modifying the seek of `f` will also modify it in this object, so try not to use `f` outside,
	/// or do so with some precaution.
	this (File f){
		file = f;
		closeOnDestroy = false;
		_minSeek = 0;
		_maxSeek = 0;
	}
	/// prepares this object for reading/writing an already opened file, where the read/write can only take place between a
	/// certain range.
	///
	/// When this constructor is used, file will not be closed when this object is destroyed
	/// and keep in mind that modifying the seek of `f` will also modify it in this object, so try not to use `f` outside,
	/// or do so with some precaution.
	/// The object will treat the File segment as the whole file in the functions:
	/// * seek will return relative to minSeek. i.e, if actual seek is `minSeek + 1`, it will return `1`
	/// * size will return `(maxSeek - minSeek) + 1` if the actual size is greater than maxSeek, otherwise, it will be `size - maxSeek`
	/// * `lock()` (locking whole file) will only lock the segment
	/// * `unlock()` (unlocking whole file) will only unlock the segment
	///
	/// Arguments:
	/// `f` if the File to do reading/writing on
	/// `minSeek` is the index from where reading/writing can begin from.
	/// `maxSeek` is the index after which no reading writing can be done.
	this (File f, size_t minSeek, size_t maxSeek){
		file = f;
		assert (minSeek < maxSeek, "minSeek must be smaller than maxSeek");
		this._minSeek = minSeek;
		this._maxSeek = maxSeek;
		this._maxSize = (maxSeek - minSeek) + 1;
	}
	/// destructor
	~this(){
		if (closeOnDestroy)
			file.close();
	}
	/// locks a file segment (readWrite lock)
	///
	/// Throws: Exception if this FileReader is only for a segment and it tries to access outdside that segment
	///
	/// Returns: true if lock was successful, false if already locked
	bool lock(size_t start, size_t length){
		if (_minSeek + _maxSeek > 0){
			start = start + _minSeek;
		}
		// make sure it's not accessing anything outside the segment, if there is a segment limit
		if (start + length > _maxSeek + 1){
			throw new Exception ("trying to access outside _maxSeek");
		}
		return file.tryLock(LockType.readWrite, start, length);
	}
	/// locks the whole file (readWrite lock)
	///
	/// Returns: true if lock was successful, false if alrady locked
	bool lock(){
		if (_minSeek + _maxSeek == 0){
			return file.tryLock(LockType.readWrite, 0, 0);
		}
		return file.tryLock(LockType.readWrite, _minSeek, _maxSize);
	}
	/// unlocks a file segment
	///
	/// Throws: Exception if this FileReader is only for a segment and it tries to access outdside that segment
	void unlock (size_t start, size_t length){
		if (_minSeek + _maxSeek > 0){
			start = start + _minSeek;
		}
		// make sure it's not accessing anything outside the segment, if there is a segment limit
		if (start + length > _maxSeek + 1){
			throw new Exception ("trying to access outside _maxSeek");
		}
		file.unlock (start, length);
	}
	/// unlocks the whole file
	void unlock (){
		if (_minSeek + _maxSeek == 0){
			file.unlock (0, file.size);
		}else if (file.size > 0){
			file.unlock(_minSeek, _maxSize);
		}
	}
	/// reads a number of bytes
	///
	/// Returns: the bytes read. If there were not enough bytes left to read in the file, an array of smaller size is returned
	///
	/// Throws: Exception (ErrnoException) in case of an error
	ubyte[] read (size_t n){
		ubyte[] buffer;
		buffer.length = this.size - this.seek > n ? n : this.size - this.seek;
		file.rawRead(buffer);
		return buffer;
	}
	/// reads till a specific byte is reached, or if eof is reached
	///
	/// Returns: the bytes read including the terminating byte
	///
	/// Throws: Exception (ErrnoException) in case of an error
	ubyte[] read (ubyte terminateByte){
		ubyte[] r;
		while (this.seek < this.size){
			ubyte[1] currentByte;
			file.rawRead(currentByte);
			r = r ~ currentByte[0];
			if (currentByte[0] == terminateByte){
				break;
			}
		}
		return r;
	}
	/// writes some bytes
	///
	/// Throws: Exception (ErrnoException) in case of an error
	void write (ubyte[] buffer){
		// make sure it won't overflow the _maxSeek
		if (buffer.length + this.seek > _maxSize){
			buffer = buffer.dup;
			buffer.length = _maxSize - this.seek;
		}
		file.rawWrite(buffer);
	}
	/// Removes a number of bytes from the file, starting at an index.
	///
	/// Arguments:
	/// `index` is index to begin removing from
	/// `length` is number of bytes to remove
	/// `chunkSize` is the number of bytes to shift in one iteration
	///
	/// Returns: true if done, false if not, or index was out of bounds TODO add tests for this
	bool remove (size_t index, size_t length){
		if (this.size <= index || this.size - index < length)
			return false;
		try{
			for (this.seek = index+length; this.seek < this.size;){
				ubyte[] toShift = this.read(length);
				this.seek = this.seek - length;
				this.write (toShift);
			}
			truncate(this.size - length);
		}catch(Exception e){
			.destroy (e);
			return false;
		}
		return true;
	}
	/// inserts some bytes at the seek. i.e, shifts existing data from index=seek+1 onwards and makes space for new data, and writes it
	///
	/// Does not work if minSeek or maxSeek is set
	///
	/// Returns: true if successful, false if not
	bool insert (ubyte[] data){
		// TODO make this
	}
	/// truncates a file, i.e removes last byte(s) from file.
	///
	/// Does not work if minSeek and/or maxSeek were non-zero.
	///
	/// TODO: read file `byChunk`, write it to new file, excluding last byte(s), replace old file with newfile; will be faster
	///
	/// Arguments:
	/// `newSize` is the new number of bytes in file.
	/// `onFailTrySlow` if true, when `SetEndOfFile` or `ftruncate` fails, it'll use a slower method that might work
	///
	/// Returns: true if file was truncated, false if not, for example if the file size was less than newSize TODO add tests
	bool truncate(size_t newSize, bool onFailTrySlow=false){
		if (_minSeek + _maxSeek != 0 || newSize < this.size){
			return false;
		}
		try{
			version (Posix){
				import core.sys.posix.unistd: ftruncate;
				ftruncate(file.fileno, newSize);
			}
			version (Windows){
				import core.sys.windows.windows: SetEndOfFile;
				size_t oldSeek = this.seek;
				this.seek = newSize-1;
				SetEndOfFile (file.HANDLE);
				this.seek = oldSeek;
			}
		}catch (Exception e){
			return false;
		}
		return (file.size == newSize);
	}
	/// from where the next byte will be read/write
	@property ulong seek (){
		if (_maxSeek + _minSeek == 0){
			return file.tell();
		}
		ulong actualSeek = file.tell();
		if (actualSeek < _minSeek){
			this.seek = 0;
		}else if (actualSeek > _maxSeek){
			this.seek = _maxSeek;
		}
		return file.tell() - _minSeek;
	}
	/// from where the next byte will be read/write
	@property ulong seek (ulong newSeek){
		if (_maxSeek + _minSeek == 0){
			file.seek (newSeek, SEEK_SET);
			return file.tell();
		}
		newSeek += _minSeek;
		if (newSeek > _maxSeek){
			newSeek = _maxSeek;
		}
		file.seek (newSeek, SEEK_SET);
		return file.tell() - _minSeek;
	}
	/// number of bytes in file
	@property ulong size (){
		ulong actualSize = file.size();
		if (actualSize > _maxSize){
			actualSize = _maxSize;
		}
		return actualSize;
	}
	/// the filename currently being read/written
	@property string filename (){
		return _filename;
	}
}
///
unittest{
	import std.path : dirSeparator;
	// delete the file if it already exists, so it wont mess up the tests
	string fname = tempDir ~ dirSeparator ~ "utilsfilereader";
	if (fname.exists){
		remove (fname);
	}
	FileReader fread = new FileReader(fname);
	assert (fread.seek == 0, "seek is not zero at file open");
	assert (fread.size == 0, "size is not zero for newly created file");
	assert (fread.filename == fname, "filename is not "~fname);
	// first fill it with some data
	fread.write ([1,3,4,5,6,7,8,0,8,7,6,5,4,3,2,1]);
	assert (fread.seek == 16);
	assert (fread.size == 16);
	fread.seek = 1;
	fread.write ([2]);
	assert (fread.seek == 2);
	assert (fread.size == 16);
	// close it, and see if opening existing files works
	.destroy (fread);
	fread = new FileReader(fname);
	assert (fread.size == 16);
	assert (fread.filename == fname);
	assert (fread.seek == 0);
	/// test read-until-terminator
	assert (fread.read(cast(ubyte)0) == [1,2,4,5,6,7,8,0]);
	assert (fread.seek == 8);
	/// test read-number of bytes
	assert (fread.read(cast(size_t)5) == [8,7,6,5,4]);
	assert (fread.seek == 13);
	assert (fread.read(999) == [3,2,1]);
	/// test move-seek and read
	fread.seek = 2;
	assert (fread.read(cast(ubyte)0) == [4,5,6,7,8,0]);
	/// close it
	.destroy (fread);
	remove (fname);
}*/

/// For reading/writing sequentially to a ubyte[]
///
/// be careful using maxSize and grow, they're not tested
class ByteStream{
private:
	ubyte[] _stream;
	size_t _seek;
	bool _grow;
	size_t _maxSize;
public:
	/// constructor
	///
	/// `grow` is whether the stream is allowed to grow in size while writing
	/// `maxSize` is the maximum size stream is allowed to grow to (0 for no limit)
	this(bool grow = true, size_t maxSize = 0){
		_grow = grow;
		_maxSize = maxSize;
	}
	~this(){
		.destroy(_stream);
	}

	/// Seek position (i.e: next read/write index)
	@property size_t seek(){
		return _seek;
	}
	/// ditto
	@property size_t seek(size_t newVal){
		return _seek = newVal > _stream.length ? _stream.length : newVal;
	}

	/// if the stream is allowed to grow in size while writing
	@property bool grow(){
		return _grow;
	}
	/// ditto
	@property bool grow(bool newVal){
		return _grow = newVal;
	}

	/// maximum size stream is allowed to grow to, 0 for no limit.
	///
	/// This is enforced while writing, or changing `ByteStream.size`
	@property size_t maxSize(){
		return _maxSize;
	}
	/// ditto
	@property size_t maxSize(size_t newVal){
		_maxSize = newVal;
		if (_seek > _maxSize)
			_seek = _maxSize;
		return _maxSize;
	}

	/// The stream
	@property ubyte[] stream(){
		return _stream;
	}
	/// ditto
	@property ubyte[] stream(ubyte[] newVal){
		return _stream = newVal;
	}

	/// Size, in bytes, of stream
	@property size_t size(){
		return _stream.length;
	}
	/// Size, setter. if new size is >maxSize, size is set to maxSize
	@property size_t size(size_t newVal){
		_stream.length = _maxSize < newVal ? _maxSize : newVal;
		if (_seek > _stream.length)
			_seek = _stream.length;
		return _stream.length;
	}

	/// Writes this stream to a file
	///
	/// Returns: true if successful, false if not
	bool toFile(string fname){
		try{
			std.file.write(fname, _stream);
		}catch (Exception e){
			.destroy(e);
			return false;
		}
		return true;
	}

	/// Reads a stream from file.
	/// if successful, seek and maxSize are set to 0;
	///
	/// Returns: true if done successfully, false if not
	bool fromFile(string fname){
		try{
			_stream = cast(ubyte[])std.file.read(fname);
		}catch (Exception e){
			.destroy(e);
			return false;
		}
		_seek = 0;
		_maxSize = 0;
		return true;
	}

	/// Reads a slice from the stream into buffer. Will read number of bytes so as to fill `buffer`
	///
	/// Returns: number of bytes read
	size_t readRaw(ubyte[] buffer){
		immutable size_t len =
			_seek + buffer.length > _stream.length
			? _stream.length - _seek
			: buffer.length;
		buffer[0 .. len] = _stream[_seek .. _seek + len];
		_seek += len;
		return len;
	}

	/// Reads at a seek without changing seek. **Does not work for dynamic arrays**
	///
	/// Will still return an invalid value if reading outside stream
	/// Sets `incompleteRead` to true if there were less bytes in stream that T.sizeof
	///
	/// Returns: the data read at position
	T readAt(T)(size_t at, ref bool incompleteRead){
		ByteUnion!T r;
		at = at > _stream.length ? _stream.length : at;
		immutable size_t len =
			at + r.array.length > _stream.length
			? _stream.length - at
			: r.array.length;
		incompleteRead = len < r.array.length;
		r.array[0 .. len] = _stream[at .. at + len];
		return r.data;
	}
	/// ditto
	T readAt(T)(size_t at){
		bool dummyBool;
		return readAt!T(at, dummyBool);
	}
	/// Reads a data type T from current seek. **Do not use this for reading arrays**
	///
	/// Will return invalid data if there are insufficient bytes to read from.
	/// Sets `incompleteRead` to true if there were less bytes in stream that T.sizeof
	/// If value of `n` is non-zero, that number of bytes will be read.
	///
	/// Returns: the read data
	T read(T)(ref bool incompleteRead, ubyte n=0){
		ByteUnion!T u;
		size_t readCount;
		if (n == 0 || n > T.sizeof)
			readCount = readRaw(u.array);
		else
			readCount = readRaw(u.array[0 .. n]);
		incompleteRead = readCount < n;
		if (n > T.sizeof)
			_seek += n - T.sizeof;
		return u.data;
	}
	/// ditto
	T read(T)(ubyte n=0){
		bool dummyBool;
		return read!T(dummyBool, n);
	}
	/// Reads an array.
	///
	/// in case of insufficient bytes in stream, will return array of correct length but missing bytes at end.
	/// `readCount` is the number of elements that were actually read (this can be < length if stream doesnt have enough bytes)
	/// `n` is the number of bytes to read for length of array, default(`0`) is `size_t.sizeof`
	///
	/// Returns: the read array
	T[] readArray(T)(ref size_t readCount, ubyte n=0){
		immutable size_t len = read!size_t(n);
		T[] r;
		r.length = len / T.sizeof;
		readCount = readRaw((cast(ubyte*)r.ptr)[0 .. r.length * T.sizeof]) / T.sizeof;
		return r;
	}
	/// ditto
	T[] readArray(T)(ubyte n=0){
		size_t dummyUint;
		return readArray!T(dummyUint, n);
	}
	/// Writes data at seek. **Do not use this for arrays**
	///
	/// `n` is number of bytes to actually write, default (0) is `T.sizeof`
	///
	/// Returns: true if written, false if not (could be because stream not allowed to grow, or max size reached)
	bool write(T)(T data, ubyte n=0){
		ByteUnion!T u;
		u.data = data;
		immutable size_t newSize = _seek + (n == 0 ? u.array.length : n); // size after writing
		if (newSize > _stream.length){
			if (!_grow || (_maxSize && newSize > _maxSize))
				return false;
			_stream.length = newSize;
		}
		if (n == 0 || n > u.array.length){
			_stream[_seek .. _seek + u.array.length] = u.array;
			_seek += u.array.length;
			if (n <= u.array.length)
				return true;
			n -= u.array.length;
			if (n){
				_stream[_seek .. _seek + n] = 0;
				_seek += n;
			}
			return true;
		}
		_stream[_seek .. _seek + n] = u.array[0 .. n];
		_seek += n;
		return true;
	}
	/// Writes an array without its size.
	///
	/// Returns: number of bytes written, **not the number of elements**
	size_t writeRaw(T)(T[] data){
		size_t len = data.length * T.sizeof;
		if (_seek + len > _stream.length){
			if (!_grow)
				len = _stream.length - _seek;
			else if (_maxSize && _seek + len > _maxSize)
				len = _maxSize - _seek;
			_stream.length = _seek + len;
		}
		_stream[_seek .. _seek + len] = (cast(ubyte*)data.ptr)[0 .. len];
		_seek += len;
		return len;
	}
	/// Writes (overwriting existing) data `at` a seek, without changing seek.
	///
	/// `n` is number of bytes to actually write. default (0) is T.sizeof
	/// Will append to end of stream if `at` is outside stream
	///
	/// Returns: true if written successfully, false if not
	bool writeAt(T)(size_t at, T data, ubyte n = 0){
		// writing is bit complicated, so just use `write` and change seek back to original after
		immutable size_t prevSeek = _seek;
		_seek = at > _stream.length ? _stream.length : at;
		immutable bool r = this.write(data, n);
		_seek = prevSeek;
		return r;
	}
	/// Writes an array at seek.
	///
	/// `n` is the number of bytes to use for storing length of array, default (`0`) is `size_t.sizeof`
	///
	/// Returns: true if written, false if not (due to maxSize reached or not allowed to grow)
	bool writeArray(T)(T[] data, ubyte n=0){
		immutable size_t newSize = _seek + (n == 0 ? size_t.sizeof : n) + (data.length * T.sizeof);
		if (newSize > _stream.length){
			if (!_grow || (_maxSize && newSize > _maxSize))
				return false;
			_stream.length = newSize;
		}
		if (this.write(data.length * T.sizeof, n)){
			return writeRaw(data) == data.length * T.sizeof;
		}
		return false; // something bad went wrong, while writing size
	}
}
///
unittest{
	ByteStream stream = new ByteStream();
	ubyte[] buffer;
	uint[] uintArray = [12_345, 123_456, 1_234_567, 12_345_678, 123_456_789];

	stream.write(1024, 8); // 1024 as ulong
	stream.seek = 0;
	assert(stream.read!uint(8) == 1024);
	assert(stream.seek == 8, stream.seek.to!string);
	stream.writeRaw(uintArray);
	stream.seek = 8;
	buffer.length = 50;
	stream.readRaw(buffer);
	assert((cast(uint*)buffer.ptr)[0 .. 5] == uintArray);

	stream.seek = 0;
	stream.writeArray(uintArray, 6);
	assert(stream.seek == (uintArray.length * 4) + 6);
	stream.seek = 0;
	uintArray = stream.readArray!(uint)(6);
	assert (uintArray == [12_345, 123_456, 1_234_567, 12_345_678, 123_456_789], uintArray.to!string);

	stream.seek = 0;
	stream.writeRaw(uintArray);
	stream.writeAt(0, cast(uint)50);
	buffer.length = uintArray.length * uint.sizeof;
	stream.seek = 0;
	assert(stream.readRaw(buffer) == buffer.length);
	uintArray = (cast(uint*)buffer.ptr)[0 .. uintArray.length];
	assert(uintArray[0] == 50 && uintArray[1 .. $] == [123_456, 1_234_567, 12_345_678, 123_456_789]);
	assert(stream.readAt!uint(4) == 123_456);
}

/// used by Tree class to hold individual nodes in the tree
struct TreeNode(T){
	T data; /// the data stored
	TreeNode!(T)* parentPtr; /// pointer to the parent node, if this is null, this is the root of the tree
	TreeNode!(T)*[] childNodes; /// stores child nodes
	/// constructor
	this(T dataToStore){
		data = dataToStore;
	}
	/// constructor
	this(TreeNode!(T)* parent){
		parentPtr = parent;
	}
	/// constructor
	this(TreeNode!(T)*[] children){
		childNodes = children.dup;
	}
	/// constructor
	this(T dataToStore, TreeNode!(T)*[] children, TreeNode!(T)* parent){
		data = dataToStore;
		childNodes = children.dup;
		parentPtr = parent;
	}
}
/// To make reading a Tree (made up of TreeNode) a bit easier
///
/// and while using it, make sure you do not make a loop in TreeNodes by putting a parent or parent's parent in a node's childNodes,
/// doing so will cause an infinite loop, TreeReader cannot currently handle this
struct TreeReader(T){
	/// the root node
	TreeNode!(T)* root;
	/// .destroy()s children of the root, including children of children and so on, the root is also .destroy-ed
	void clear(){
		/// called by iterate to destroy a node
		static bool destroyNode(TreeNode!(T)* node){
			.destroy(*node);
			return true;
		}
		// start killing every node
		this.iterate(&destroyNode);
	}
	/// counts and returns number of nodes in the tree
	///
	/// Returns: the number of nodes in the tree, counting all child-nodes and their child-nodes and so on
	size_t count(){
		// stores the count
		size_t r = 0;
		/// used to "receive" nodes from iterate
		bool increaseCount(TreeNode!(T)* node){
			r ++;
			return true;
		}
		// start counting
		iterate(&increaseCount);
		return r;
	}
	/// counts and returns number of nodes in the tree
	///
	/// if `doCount` is not null, only nodes for which `doCount` function returns true will be counted
	///
	/// Returns: number of nodes for which `doCount(node)` returned true
	size_t count(bool function(TreeNode!(T)*) doCount=null){
		/// stores the count
		size_t r = 0;
		/// used to "receive" nodes from iterate
		bool increaseCount(TreeNode!(T)* node){
			if (doCount !is null && (*doCount)(node)){
				r ++;
			}
			return true;
		}
		// start counting
		iterate(&increaseCount);
		return r;
	}
	/// calls a function on every node
	///
	/// loop is terminated as soon as false is returned from function
	/// No recursion is used, as it uses a stack to store which nodes it has to call a function on
	void iterate(bool function(TreeNode!(T)*) func){
		if (func is null){
			throw new Exception ("func cannot be null in iterate");
		}
		/// stores all the nodes of whose childNodes's  have to be sent
		Stack!(TreeNode!(T)*) nodes = new Stack!(TreeNode!(T)*);
		/// start from root
		nodes.push(root);
		while (nodes.count > 0){
			/// the node whose childs are being currently being "sent":
			TreeNode!(T)* currentNode = nodes.pop;
			// "send" this node
			func(currentNode);
			// and have to send their childNodes too
			foreach (childPtr; (*currentNode).childNodes){
				nodes.push(childPtr);
			}
		}
		.destroy(nodes);
	}
	/// calls a delegate on every node
	///
	/// loop is terminated as soon as false is returned from function
	/// No recursion is used, as it uses a stack to store which nodes it has to call a delegate on
	void iterate(bool delegate(TreeNode!(T)*) func){
		if (func is null){
			throw new Exception ("func cannot be null in iterate");
		}
		/// stores all the nodes of whose childNodes's  have to be sent
		Stack!(TreeNode!(T)*) nodes = new Stack!(TreeNode!(T)*);
		/// start from root
		nodes.push(root);
		while (nodes.count > 0){
			/// the node whose childs are being currently being "sent":
			TreeNode!(T)* currentNode = nodes.pop;
			// "send" this node
			func(currentNode);
			// and have to send their childNodes too
			foreach (childPtr; (*currentNode).childNodes){
				nodes.push(childPtr);
			}
		}
		.destroy(nodes);
	}
}
///
unittest{
	TreeReader!int tree;
	// testing iterate
	// make a sample tree
	TreeNode!int rootNode;
	rootNode.data = 0;
	// childNodes of root
	TreeNode!int rootChild0 = TreeNode!int(1), rootChild1=TreeNode!int(2);
	// childNodes of rootChild0
	TreeNode!int child0child0 = TreeNode!int(3), child0child1 = TreeNode!int(4);
	// childNodes of rootChild1
	TreeNode!int child1child0 = TreeNode!int(5), child1child1 = TreeNode!int(6);
	// arrange them in a tree
	rootNode.childNodes = [&rootChild0, &rootChild1];
	rootChild0.childNodes = [&child0child0, &child0child1];
	rootChild1.childNodes = [&child1child0, &child1child1];
	tree.root = &rootNode;
	// check if iterate's working
	int[] iteratedNodes;
	tree.iterate((TreeNode!(int)* node){iteratedNodes ~= (*node).data; return true;});
	// make sure each number was iterated
	assert ([0,1,2,3,4,5,6].matchElements(iteratedNodes), "TreeReader.iterate did not iterate through all nodes");
	/// now test count
	assert (tree.count == 7, "TreeReader.count returned invalid count");
	/// thats all unit tests for now, so destroy all nodes now
	tree.clear;
}
