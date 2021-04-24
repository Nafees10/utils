/++
	Some data structures
+/
module utils.ds;

import std.file;
import std.stdio;
import std.conv : to;
import utils.misc;

/// Use to manage dynamic arrays that frequently change lengths
/// 
/// Provides more functionality for arrays, like searching in arrays, removing elements...
class List(T){
private:
	T[] list; /// the actual list
	uinteger taken=0; /// how many elements are actually stored in the list
	uinteger extraAlloc; /// how many extra elements to make space for when list length runs out
	uinteger _seek = 0; /// where to read/write next if index isn't specified
public:
	/// constructor
	/// 
	/// extraCount is the number of extra space to make for new elements when making "room" for new elements
	this(uinteger extraCount = 4){
		extraAlloc = extraCount;
	}
	/// appends an element to the list
	void append(T dat){
		if (taken==list.length){
			list.length+=extraAlloc;
		}
		list[taken] = dat;
		taken++;
	}
	/// appends an array to the list
	void append(T[] dat){
		list = list[0 .. taken]~dat.dup;
		taken = list.length;
	}
	/// Changes the value of element at an index.
	/// 
	/// Arguments:
	/// `dat` is the new data
	/// 
	/// Returns: false if index is out of bounds, true if successful
	bool set(uinteger index, T dat){
		if (index >= taken){
			return false;
		}
		list[index]=dat;
		return true;
	}
	/// Changes the value of element at seek. Seek is increased by one
	/// 
	/// Arguments:
	/// `value` is the new value
	/// 
	/// Returns: true if successful, false if seek if out of bounds
	bool write (T value){
		if (_seek >= taken){
			return false;
		}
		list[_seek] = value;
		_seek ++;
		return true;
	}
	/// Changes the value of elements starting at index=seek. Seek is increased by number of elements affected
	/// 
	/// Arguments:
	/// `elements` is the array of new values of the elements
	/// 
	/// Returns: true if successful, false if not enough elements in list or seek out of bounds
	bool write (T[] elements){
		if (_seek + elements.length >= taken){
			return false;
		}
		list[_seek .. _seek + elements.length] = elements.dup;
		_seek += elements.length;
		return true;
	}
	/// Reads an element at index=seek. Seek is increased by one
	/// 
	/// Returns: the read element
	/// 
	/// Throws: Exception if seek is out of bounds
	T read(){
		if (_seek >= taken){
			throw new Exception ("seek out of bounds");
		}
		T r = list[_seek];
		_seek ++;
		return r;
	}
	/// Reads a number of elements starting at index=seek. Seek is increased by number of elements
	/// 
	/// Arguments:
	/// `buffer` is the array into which the elements will be read. set `buffer.length` to number of elements to read
	/// 
	/// Returns: number of elements read into the buffer
	uinteger read(ref T[] buffer){
		if (_seek >= taken || buffer.length == 0){
			return 0;
		}
		uinteger count = _seek + buffer.length < taken ? buffer.length : taken - _seek;
		buffer = list[_seek .. _seek + count].dup;
		_seek += count;
		return count;
	}
	/// The seek position
	@property uinteger seek(){
		return _seek;
	}
	/// ditto
	@property uinteger seek(uinteger newSeek){
		return _seek = newSeek;
	}
	/// Removes last elements(s) starting from an index
	/// 
	/// Arguments:
	/// `count ` is number of elements to remove
	/// 
	/// Returns: false if range is out of bounds, true if successful
	bool remove(uinteger index, uinteger count=1){
		if (index + count >= taken){
			return false;
		}
		integer i;
		integer till=taken-count;
		for (i=index;i<till;i++){
			list[i] = list[i+count];
		}
		list.length-=count;
		taken-=count;
		return true;
	}
	/// Removes number of elements from end of list
	/// 
	/// Returns: true if successful, false if not enough elements to remove
	bool removeLast(uinteger count = 1){
		if (count > taken){
			return false;
		}
		taken -= count;
		return true;
	}
	/// shrinks the size of the list, removing last elements.
	/// 
	/// Returns: true if shrunk, false if not for example if `newSize` was greater than actual size
	bool shrink(uinteger newSize){
		if (newSize < taken){
			list.length=newSize;
			taken = list.length;
			return true;
		}
		return false;
	}
	/// Returns: how many elements can be appended before list length needs to increase
	@property uinteger freeSpace(){
		return list.length - taken;
	}
	/// make more free space for new elements, or reduce it. To reduce, use n as negative. To decrease by 2, `n=-2`
	/// 
	/// Returns: true if done, false if not done, for example if there wasn't enough free space in list to be removed
	bool setFreeSpace(integer n){
		if (n < 0 && -n > list.length - taken){
			return false;
		}
		try{
			list.length = list.length + n;
		}catch (Exception e){
			.destroy (e);
			return false;
		}
		return true;
	}
	/// removes the free space, if any, for adding new elements. Call this when done with adding to list.
	void clearFreeSpace(){
		list.length = taken;
	}
	/// Inserts an array into this list
	/// 
	/// Returns: true if done, false if index out of bounds, or not done
	bool insert(uinteger index, T[] dat){
		if (index >= taken){
			return false;
		}
		list = list[0 .. index] ~ dat.dup ~ list[index .. taken];
		taken = list.length;
		return true;
	}
	/// Inserts an element into this list
	/// 
	/// Returns: true if done, false if index out of bounds, or not done
	bool insert(uinteger index, T dat){
		if (index >= taken){
			return false;
		}
		list = list[0 .. index] ~ dat ~ list[index .. taken];
		taken = list.length;
		return true;
	}
	/// Writes the list to a file.
	/// 
	/// Arguemnts:
	/// `s` is the filename  
	/// `sp` is the separator, it will be added to the end of each list-element  
	/// 
	/// Returns: true if done, false if not due to some Exception
	bool saveFile(string s, T sp){
		try{
			File f = File(s,"w");
			uinteger i;
			for (i=0;i<taken;i++){
				f.write(list[i],sp);
			}
			f.close;
		}catch (Exception e){
			.destroy(e);
			return false;
		}
		return true;
	}
	/// Reads an element at an index
	/// 
	/// Returns: the element read
	/// 
	/// Throws: Exception if index out of bounds
	T read(uinteger index){
		if (index >= taken){
			throw new Exception("index out of bounds");
		}
		return list[index];
	}
	/// Read a slice from the list.
	/// 
	/// Returns: the elements read
	/// 
	/// Throws: Exception if index out of bounds
	T[] read(uinteger index,uinteger i2){
		if (index >= taken){
			throw new Exception("index out of bounds");
		}
		return list[index .. i2].dup;
	}
	/// Returns: pointer to element at an index
	/// 
	/// Be careful that the pointer might not be valid after the list has been resized, so try only to use it after all appending is done
	/// 
	/// Throws: Exception if index out of bounds
	T* readPtr(uinteger index){
		if (index >= taken){
			throw new Exception ("index out of bounds");
		}
		return &(list[index]);
	}
	/// Reads the last element in list.
	/// 
	/// Returns: the last element in list
	/// 
	/// Throws: Exception if list length is zero
	T readLast(){
		if (taken == 0){
			throw new Exception ("List has no elements, can not readLast");
		}
		return list[taken-1];
	}
	/// Reads number of elements from end of list
	/// 
	/// Returns: the elements read
	/// 
	/// Throws: Exception if not enough elements i.e range out of bounds
	T[] readLast(uinteger count){
		if (count > taken){
			throw new Exception ("range out of bounds");
		}
		return list[taken-count..taken].dup;
	}
	/// Returns: length of the list
	@property integer length(){
		return taken;
	}
	/// Exports this list into a array
	/// 
	/// Returns: the array containing the elements in this list
	T[] toArray(){
		return list[0 .. taken].dup;
	}
	/// Loads list from an array
	void loadArray(T[] newList){
		uinteger i;
		list = newList.dup;
		taken = newList.length;
		_seek = 0;
	}
	/// empties the list
	void clear(){
		list = [];
		taken = 0;
		_seek = 0;
	}
	/// Returns: index of the first matching element. -1 if not found
	/// 
	/// Arguments:
	/// `dat` is the element to search for  
	/// `i` is the index from where to start, default is 0  
	/// `forward` if true, searches in a forward direction, from lower index to higher  
	integer indexOf(bool forward=true)(T dat, integer i=0){
		static if (forward){
			for (;i<taken;i++){
				if (list[i]==dat){break;}
				if (i==taken-1){i=-1;break;}
			}
		}else{
			for (;i>=0;i--){
				if (list[i]==dat){break;}
				if (i==0){i=-1;break;}
			}
		}
		if (taken==0){
			i=-1;
		}
		return i;
	}
}
///
unittest{
	List!ubyte list = new List!ubyte(4);
	//`List.insert` and `List.add` and `List.toArray`
	list.append(0);
	list.append(1);
	list.insert(1, 2);
	assert(list.toArray() == [0, 2, 1]);
	//`List.indexOf`
	assert(list.indexOf(1) == 2);
	//`List.clear`
	list.clear;
	assert(list.length == 0);
	//`List.loadArray`
	list.loadArray([0, 1, 2, 3]);
	assert(list.length == 4);
	assert(list.indexOf(3) == 3);
	//`List.addArray`
	list.append([4, 5, 6, 7, 8]);
	assert(list.length == 9);
	//`List.set` and `List.read`
	list.set(0, 1);
	assert(list.read(0) == 1);
	//`List.readLast`
	assert(list.readLast() == 8);
	assert(list.readLast(2) == [7, 8]);
	//`List.readRange`
	assert(list.read(0, 2) == [1, 1]);
	//`List.remove`
	list.remove(0, 2);
	assert(list.read(0) == 2);
	//`List.removeLast`
	list.removeLast(2);
	assert(list.readLast() == 6);
	//`List.freeSpace`
	list.clear;
	foreach (i; cast(ubyte[])[0,1,2])
		list.append(i);
	assert(list.freeSpace == 1, to!string(list.freeSpace));
	list.append(3);
	assert(list.freeSpace == 0);
	list.setFreeSpace(6);
	assert(list.freeSpace == 6 && list.length == 4);
	list.setFreeSpace(-3);
	assert(list.freeSpace == 3);
	assert(list.setFreeSpace(-10) == false);
	//reading/writing with seek
	list.clear;
	assert(list.seek == 0);
	list.append([0,1,2,3,4,5,6,7,8]);
	assert(list.seek == 0);
	ubyte[] buffer;
	buffer.length = 4;
	assert(list.read(buffer) == 4);
	assert(buffer == [0,1,2,3]);
	assert(list.seek == 4);
	assert(list.read == 4);
	assert(list.write(5) == true);
	assert(list.read(buffer) == 3);
	assert(buffer[0 .. 3] == [6,7,8]);
	assert(list.seek == 9);
	//`List.readPtr`
	list.clear;
	list.append ([0,1,2,3,4,5]);
	ubyte* ptr = list.readPtr(5);
	*ptr = 4;
	assert (list.toArray == [0,1,2,3,4,4]);

	destroy(list);
}

/// A basic stack with push, and pop
class Stack(T){
private:
	struct stackItem(T){
		T data; /// the data this item holds
		stackItem* prev; /// pointer to previous stackItem
	}
	stackItem!(T)* lastItemPtr;
	uinteger itemCount;
public:
	this(){
		lastItemPtr = null;
		itemCount = 0;
	}
	~this(){
		clear;
	}
	/// Appends an item to the stack
	void push(T item){
		stackItem!(T)* newItem = new stackItem!T;
		(*newItem).data = item;
		(*newItem).prev = lastItemPtr;
		lastItemPtr = newItem;
		//increase count
		itemCount ++;
	}
	/// Appends an array of items to the stack
	void push(T[] items){
		// put them all in stackItem[]
		stackItem!(T)*[] newItems;
		newItems.length = items.length;
		for (uinteger i = 0; i < items.length; i ++){
			newItems[i] = new stackItem!T;
			(*newItems[i]).data = items[i];
		}
		// make them all point to their previous item, except for the first one, which should point to `lastItemPtr`
		for (uinteger i = newItems.length - 1; i > 0; i --){
			(*newItems[i]).prev = newItems[i-1];
		}
		(*newItems[0]).prev = lastItemPtr;
		lastItemPtr = newItems[newItems.length - 1];
		//increase count
		itemCount += newItems.length;
	}
	/// pops an item from stack
	/// 
	/// Returns: the item poped
	/// 
	/// Throws: Exception if stack is empty
	T pop(){
		// make sure its not null
		if (lastItemPtr !is null){
			T r = (*lastItemPtr).data;
			// delete it from stack
			stackItem!(T)* prevItem = (*lastItemPtr).prev;
			destroy(*lastItemPtr);
			lastItemPtr = prevItem;
			//decrease count
			itemCount --;
			return r;
		}else{
			throw new Exception("Cannot pop from empty stack");
		}
	}
	/// Reads and removes an array of items from the stack,
	/// 
	/// Throws: Exception if there are not enough items in stack
	/// 
	/// Returns: the items read
	/// 
	/// Arguments:
	/// `count` is the number of elements to return  
	/// `reverse`, if true, elements are read in reverse, last-pushed is last in array  
	T[] pop(bool reverse=false)(uinteger count){
		//make sure there are enough items
		if (itemCount >= count){
			T[] r;
			r.length = count;
			stackItem!(T)* ptr = lastItemPtr;
			static if (reverse){
				for (integer i = count-1; i >= 0; i --){
					r[i] = (*ptr).data;
					ptr = (*ptr).prev;
					// delete this item
					.destroy(*lastItemPtr);
					lastItemPtr = ptr;
				}
			}else{
				for (uinteger i = 0; i < count; i ++){
					r[i] = (*ptr).data;
					ptr = (*ptr).prev;
					//delete it
					.destroy(*lastItemPtr);
					lastItemPtr = ptr;
				}
			}
			//decrease count
			itemCount -= r.length;
			return r;
		}else{
			throw new Exception("Not enough items in stack");
		}
	}
	/// Empties the stack, pops all items
	void clear(){
		// go through all items and delete em
		stackItem!(T)* ptr;
		ptr = lastItemPtr;
		while (ptr !is null){
			stackItem!(T)* prevPtr = (*ptr).prev;
			destroy(*ptr);
			ptr = prevPtr;
		}
		lastItemPtr = null;
		itemCount = 0;
	}
	/// Number of items in stack
	@property uinteger count(){
		return itemCount;
	}
}
///
unittest{
	Stack!ubyte stack = new Stack!ubyte;
	//`Stack.push` and `Stack.pop`
	stack.push(0);
	stack.push([1, 2]);
	assert(stack.pop == 2);
	assert(stack.pop(2) == [1, 0]);
	stack.push([1, 0]);
	assert(stack.pop!(true)(2) == [1, 0]);
	//`Stack.clear` && `Stack.count`
	stack.push(0);
	assert(stack.count == 1);
	stack.clear;
	assert(stack.count == 0);
	stack.destroy;
}

/// A FIFO (First In is First Out, first element pushed will be removed first) stack
class FIFOStack(T){
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
	uinteger _count;
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
	@property uinteger count(){
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
			(*toPush[toPush.length-1]).next = null;
			// now "insert" it
			if (lastItemPtr is null){
				firstItemPtr = toPush[0];
			}else{
				(*lastItemPtr).next = toPush[0];
			}
			lastItemPtr = toPush[toPush.length-1];
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
	T[] pop(uinteger popCount){
		if (count == 0){
			throw new Exception("Cannot pop from empty stack");
		}
		if (_count < popCount){
			popCount = _count;
		}
		uinteger i = 0;
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

/// To manage allocating extra for cases like lists where you need to create new objects often. Also manages initializing the objects  
/// through a init function.
/// Creates a number of extra objects at one time, so it has to allocate memory less often.
class ExtraAlloc(T){
private:
	/// stores the free objects.
	FIFOStack!T _store;
	/// number of elements to allocate at one time
	uinteger _allocCount;
	/// max number of free elements present at one time, if more are present, extra are freed
	uinteger _maxCount;
	/// the delegate that will be called to get a new object
	T delegate() _initFunction;
public:
	/// constructor
	this (uinteger extraAllocCount, uinteger maxAllocCount, T delegate() initFunction){
		_store = new FIFOStack!T;
		_allocCount = extraAllocCount;
		_maxCount = maxAllocCount;
		_initFunction = initFunction;
	}
	/// destructor. Destroys all objects created by this
	~this (){
		while (_store.count > 0){
			.destroy(_store.pop);
		}
		.destroy(_store);
	}
	/// allocates and initializes objects to fill extraAllocCount
	/// 
	/// Returns: true if more objects were allocated, false if the queue is already full, or if the queue had more than maxAlloc, and they were freed
	bool allocate(){
		if (_store.count < _allocCount){
			T[] allocated;
			allocated.length = _allocCount - _store.count;
			for (uinteger i = 0; i < allocated.length; i ++){
				allocated[i] = _initFunction();
			}
			_store.push(allocated);
			return true;
		}
		while (_store.count > _maxCount){
			.destroy(_store.pop);
		}
		return false;
	}
	/// Returns: an object
	T get(){
		if (_store.count == 0){
			allocate();
		}
		return _store.pop;
	}
	/// Marks an object as free. Frees is if there are already enough free objects
	void free(T obj){
		_store.push(obj);
		if (_store.count > _maxCount){
			allocate();
		}
	}
}

/// A linked list, used where only reading in the forward direction is required
class LinkedList(T){
private:
	///represents an item in a linked list. contains the item, and pointer to the next item's container
	struct LinkedItem(T){
		T data;
		LinkedItem!(T)* next = null;//mark it null to show the list has ended
	}
	LinkedItem!(T)* firstItemPtr;
	LinkedItem!(T)* lastItemPtr;//the pointer of the last item, used for appending new items
	LinkedItem!(T)* nextReadPtr;//the pointer of the next item to be read
	LinkedItem!(T)* lastReadPtr;//the pointer to the last item that was read

	uinteger itemCount;//stores the total number of items

	LinkedItem!(T)*[uinteger] bookmarks;
public:
	this(){
		firstItemPtr = null;
		lastItemPtr = null;
		nextReadPtr = null;
		lastReadPtr = null;
		itemCount = 0;
	}
	~this(){
		//free all the memory occupied
		clear();
	}
	/// clears/resets the list, by deleting all elements
	void clear(){
		//make sure that the list is populated
		if (firstItemPtr !is null){
			LinkedItem!(T)* nextPtr;
			for (nextReadPtr = firstItemPtr; nextReadPtr !is null; nextReadPtr = nextPtr){
				nextPtr = (*nextReadPtr).next;
				destroy(*nextReadPtr);
			}
			//reset all variables
			firstItemPtr = null;
			lastItemPtr = null;
			nextReadPtr = null;
			lastReadPtr = null;
			itemCount = 0;
		}
	}
	/// adds a new node/element to the end of the list
	void append(T item){
		LinkedItem!(T)* ptr = new LinkedItem!(T);
		(*ptr).data = item;
		(*ptr).next = null;
		//add it to the list
		if (firstItemPtr is null){
			firstItemPtr = ptr;
			nextReadPtr = firstItemPtr;
		}else{
			(*lastItemPtr).next = ptr;
		}
		//mark this item as last
		lastItemPtr = ptr;
		//increase item count
		itemCount ++;
	}
	/// adds new nodes/items at end of list
	void append(T[] items){
		if (items.length > 0){
			LinkedItem!(T)*[] newNodes;
			newNodes.length = items.length;
			// put nodes inside the LinkedItem list
			for (uinteger i = 0; i < items.length; i++){
				newNodes[i] = new LinkedItem!T;
				(*newNodes[i]).data = items[i];
			}
			// make them point to their next node
			for (uinteger i = 0, end = newNodes.length-1; i < end; i ++){
				(*newNodes[i]).next = newNodes[i+1];
			}
			// make last item from newNodes point to null
			(*newNodes[newNodes.length-1]).next = null;
			// make the last item point to first item in newNodes
			if (firstItemPtr is null){
				firstItemPtr = newNodes[0];
				nextReadPtr = newNodes[0];
			}else{
				(*lastItemPtr).next = newNodes[0];
			}
			// mark the last item in newNodes as last in list
			lastItemPtr = newNodes[newNodes.length-1];
			//increase count
			itemCount += newNodes.length;
		}
	}
	/// removes the first node in list
	/// 
	/// If the list is empty, this function does nothing
	void removeFirst(){
		//make sure list is populated
		if (firstItemPtr !is null){
			LinkedItem!(T)* first;
			first = firstItemPtr;
			//mark the second item as first, if there isn't a second item, it'll automatically be marked null
			firstItemPtr = (*firstItemPtr).next;
			//if nextReadPtr is firstItemPtr, move it to next as well
			if (nextReadPtr is first){
				nextReadPtr = firstItemPtr;
			}
			// if the last-read is pointing to first item, null it
			if (lastReadPtr is first){
				lastReadPtr = null;
			}
			//free memory occupied by first
			destroy(*first);
			//decrease count
			itemCount --;
		}
	}
	/// removes the node that was last read using `LinkedList.read`. The last node cannot be removed using this.
	///
	/// It works by moving contents of next item into the last-read one, and removing the next node
	/// 
	/// Returns: true in case the node/item was removed, false if not
	bool removeLastRead(){
		bool r = false;
		if (lastReadPtr !is null){
			LinkedItem!(T)* thisItem = lastReadPtr;// the item to delete
			LinkedItem!(T)* nextItem = (*thisItem).next;// the item after last read
			// make sure that the item to be deleted isn't last
			if (nextItem !is null){
				// move contents of next to this item
				thisItem.data = nextItem.data;
				// set the pointer to the item after next
				thisItem.next = nextItem.next;
				// if nextItem is last item, move last item pointer to thisItem
				if (nextItem is lastItemPtr){
					lastItemPtr = thisItem;
				}
				// delete nextItem
				destroy(*nextItem);

				r = true;
			}else{
				// if there is only one item, or the pointer to second-last item is available, then it can be deleted
				if (itemCount == 1){
					// just clearing the list will do the job
					this.clear();
					// but we must increase the item count because at the end, it will be deceased by one
					itemCount ++;// a workaround...
					r = true;
				}else{
					//we'll have to read till second-last item to get be able to remove the last item
					LinkedItem!(T)* item = firstItemPtr;
					for (uinteger i = 0, end = itemCount-2; i < end; i ++){
						item = item.next;
					}
					// now `item` is pointing to second last item, make sure this is true
					if (item.next == lastItemPtr){
						//make the list end here
						item.next = null;
						// destroy last one
						destroy(*lastItemPtr);
						lastItemPtr = item;

						r = true;
					}/*else{
						something that shouldn't have gone wrong went wrong with `LinkedList.itemCount`
					}*/

				}
			}
			//decrease count
			if (r){
				itemCount --;
				//since the last-read has been removed, null that pointer, to prevent segFault
				lastReadPtr = null;
			}
		}
		return r;
	}
	/// finds an element, if found, deletes it
	/// 
	/// any function that works based on last-item-read should not be called while this is running, like in another thread...
	/// 
	/// Arguments:
	/// `toRemove` is the data to search for and delete  
	/// `count` is the number of times to search for it and delete it again. if 0, every element which is `==toRemove` is deleted  
	/// 
	/// Returns: true if was found and deleted, false if not found
	/// 
	/// Throws: Exception if failed to delete an element
	bool remove(T toRemove, uinteger count=0){
		LinkedItem!(T)* ptr = firstItemPtr, prev = null;
		bool r = false;
		uinteger removedCount = 0;
		// I'll just use a "hack" and use removeLastRead to remove it
		LinkedItem!(T)* actualLastRead = lastReadPtr;
		while (ptr && ( (count > 0 && removedCount < count) || count == 0 )){
			LinkedItem!(T)* next = (*ptr).next;
			if ((*ptr).data == toRemove){
				lastReadPtr = ptr;
				r = this.removeLastRead();
				removedCount ++;
				if (!r){
					throw new Exception("Failed to delete element in LinkedList->remove->removeLastRead");
				}
				ptr = prev;
				if (!ptr){
					ptr = firstItemPtr;
				}
				continue;
			}
			prev = ptr;
			ptr = ptr.next;
		}
		lastReadPtr = actualLastRead;
		return r;
	}
	/// searches the whole list, and any element that matches with elements in the array are deleted
	/// 
	/// any function that works based on last-item-read should not be called while this is running, like in another thread...
	/// 
	/// Arguments:
	/// `toRemove` is the array containing the elements to delete  
	/// 
	/// Returns: true on success, false if no elements matched
	/// 
	/// Throws: Exception if failed to delete an element
	bool remove(T[] toRemove){
		LinkedItem!(T)* ptr = firstItemPtr, prev = null;
		bool r = false;
		uinteger removedCount = 0;
		// I'll just use a "hack" and use removeLastRead to remove it
		LinkedItem!(T)* actualLastRead = lastReadPtr;
		while (ptr){
			LinkedItem!(T)* next = (*ptr).next;
			if (toRemove.hasElement((*ptr).data)){
				lastReadPtr = ptr;
				r = this.removeLastRead();
				if (!r){
					throw new Exception("Failed to delete element in LinkedList->remove->removeLastRead");
				}
				ptr = prev;
				if (!ptr){
					ptr = firstItemPtr;
				}
				continue;
			}
			prev = ptr;
			ptr = ptr.next;
		}
		lastReadPtr = actualLastRead;
		return r;
	}
	/// Returns: number of items that the list is holding
	@property uinteger count(){
		return itemCount;
	}
	///resets the read position, i.e: set reading position to first node, and nulls the last-read-ptr
	void resetRead(){
		nextReadPtr = firstItemPtr;
		lastReadPtr = null;
	}
	/// Returns: pointer of next node to be read, null if there are no more nodes
	/// 
	/// increments the read-position by 1, so next time it's called, the next item is read
	T* read(){
		T* r;
		if (nextReadPtr !is null){
			r = &((*nextReadPtr).data);
			//mark this item as last read
			lastReadPtr = nextReadPtr;
			//move read position
			nextReadPtr = (*nextReadPtr).next;
		}else{
			r = null;
			lastReadPtr = null;
		}
		return r;
	}
	/// Returns: the pointer to the first node in the list
	T* readFirst(){
		if (firstItemPtr !is null){
			lastReadPtr = firstItemPtr;
			return &((*firstItemPtr).data);
		}else{
			return null;
		}
	}
	/// Returns: the pointer to the last node in the list
	T* readLast(){
		if (lastItemPtr !is null){
			lastReadPtr = lastItemPtr;
			return &((*lastItemPtr).data);
		}else{
			return null;
		}
	}
	/// Reads the list into an array
	/// 
	/// Returns: the array formed from this list
	T[] toArray(){
		LinkedItem!(T)* currentNode = firstItemPtr;
		uinteger i = 0;
		T[] r;
		r.length = itemCount;
		while (currentNode !is null){
			r[i] = (*currentNode).data;
			// move to next node
			currentNode = (*currentNode).next;
			i ++;
		}
		return r;
	}
	/// Inserts a node after the position of last-read-node, i.e, to insert at position from where next item is to be read
	/// 
	/// To insert at beginning, call `resetRead` before inserting
	/// For inserting more than one nodes, use `LinkedList.insert([...])`
	void insert(T node){
		LinkedItem!(T)* newNode = new LinkedItem!T;
		(*newNode).data = node;
		// check if has to insert at beginning or at after last-read
		if (lastReadPtr !is null){
			// make new node point to the current next-to-be-read node
			(*newNode).next = lastReadPtr.next;
			// make last read node point to new node
			(*lastReadPtr).next = newNode;
		}else{
			// make this item point to first-item
			(*newNode).next = firstItemPtr;
			// mark this as first item
			firstItemPtr = newNode;
		}
		// make next read point to this node now
		nextReadPtr = newNode;
		//increase count
		itemCount ++;
	}
	/// Inserts nodes after the position of last-read-node, i.e, to insert at position from where next item is to be read
	/// 
	/// If there is no last-read-item, the item is inserted at beginning. To do this, call `resetRead` before inserting
	/// 
	/// Returns: true on success, false on failure
	void insert(T[] nodes){
		if (nodes.length > 0){
			LinkedItem!(T)*[] newNodes;
			newNodes.length = nodes.length;
			// put nodes inside the LinkedItem list
			for (uinteger i = 0; i < nodes.length; i++){
				newNodes[i] = new LinkedItem!T;
				(*newNodes[i]).data = nodes[i];
			}
			// make them point to their next node
			for (uinteger i = 0, end = newNodes.length-1; i < end; i ++){
				(*newNodes[i]).next = newNodes[i+1];
			}
			// check if has to insert at beginning or at after last-read
			if (lastReadPtr !is null && nodes.length > 0){
				// and make the last node in list point to the node after last-read
				(*newNodes[newNodes.length-1]).next = (*lastReadPtr).next;
				// make last read node point to the first new-node
				(*lastReadPtr).next = newNodes[0];
			}else{
				// insert at beginning
				(*newNodes[newNodes.length-1]).next = firstItemPtr;
				// make this the first node
				firstItemPtr = newNodes[0];
			}
			//make next read point to this
			nextReadPtr = newNodes[0];
			//increase count
			itemCount += nodes.length;
		}
	}
	/// Returns: true if list contains a node, i.e searches for a node and returns true if found
	bool hasElement(T node){
		bool r = false;
		LinkedItem!(T)* currentNode = firstItemPtr;
		while (currentNode !is null){
			if ((*currentNode).data == node){
				r = true;
				break;
			}
			// move to next node
			currentNode = (*currentNode).next;
		}
		return r;
	}
	/// matches all elements from an array to elements in list, to see if all elements in array are present in the list
	///  
	/// If the same element is present at more than one index in array, it won't work
	/// 
	/// Returns: true if list contains all elements provided in an array, else, false
	bool hasElements(T[] nodes){
		bool r = false;
		nodes = nodes.dup;
		// go through the list and match as many elements as possible
		LinkedItem!(T)* currentNode = firstItemPtr;
		while (currentNode !is null){
			// check if current node matches any in array
			integer index = nodes.indexOf((*currentNode).data);
			if (index >= 0){
				// this node matched, so remove it from the array
				nodes = nodes.deleteElement(index);
			}
			// check if all elements have been checked against
			if (nodes.length == 0){
				break;
			}
			// move to next node
			currentNode = (*currentNode).next;
		}
		// Now check if the nodes array is empty, if yes, then all nodes were matched
		if (nodes.length == 0){
			r = true;
		}
		return r;
	}
	/// Sets a "bookmark"
	/// 
	/// the returned ID can later be used to go back to the reading position at which the bookmark was placed  
	/// and be careful not to remove an item to which bookmark is pointing, because then if you moveToBookmark, it'll segfault.
	/// 
	/// Returns: the bookmark-ID
	/// 
	/// Throws: Exception if there is no last-read item
	uinteger placeBookmark(){
		if (lastReadPtr is null){
			throw new Exception("no last-read-item to place bookmark on");
		}else{
			// go through bookmarks list to find empty slot, or create a new one
			uinteger id = 0;
			while (true){
				if (id in bookmarks){
					id ++;
				}else{
					break;
				}
			}
			bookmarks[id] = lastReadPtr.next;
			return id;
		}
	}
	/// moves read position back to a bookmark using the bookmark ID
	/// 
	/// Does NOT delete the bookmark. Use `LinkedList.removeBookmark` to delete
	/// 
	/// Returns: true if successful, false if the bookmark no longer exists
	bool moveToBookmark(uinteger id){
		if (id !in bookmarks){
			return false;
		}else{
			nextReadPtr = bookmarks[id];
			return true;
		}
	}
	/// removes a bookmark using the bookmark id
	/// 
	/// Returns: true if bookmark is removed, false if it doesn't exist
	bool removeBookmark(uinteger id){
		if (id !in bookmarks){
			return false;
		}else{
			bookmarks.remove(id);
			return true;
		}
	}
	/// Removes all bookmarks
	void clearBookmarks(){
		foreach(key; bookmarks.keys){
			bookmarks.remove(key);
		}
	}
}
///
unittest{
	import std.conv : to;
	LinkedList!ubyte list = new LinkedList!ubyte;
	//`LinkedList.append` and `LinkedList.read` and `LinkedList.readFirst` and `LinkedList.readLast` and `LinkedList.resetRead`
	list.append(0);
	list.append(1);
	list.append(2);
	assert(*(list.readFirst()) == 0);
	assert(*(list.readLast()) == 2);
	assert(list.count == 3);
	list.read();// to skip, we wanna read the node at index 1 (2nd node)
	assert(*(list.read()) == 1);
	list.resetRead();
	assert(*(list.read()) == 0);
	// `LinkedList.append(T[])`:
	list.clear();
	list.append(0);
	list.append([1, 2, 3]);
	assert(list.count == 4);
	assert(list.toArray ==[0, 1, 2, 3]);
	list.clear;
	list.append([0, 1, 2]);
	list.append(3);
	assert(list.count == 4);
	assert(list.toArray == [0, 1, 2, 3]);
	//`LinkedList.clear`
	list.clear();
	list.append(3);
	list.append(4);
	assert(*(list.read()) == 3);
	assert(list.count == 2);
	list.clear();
	//`LinkedList.removeLastRead` and `Linkedlist.removeFirst`
	list.append(0);
	list.append(1);
	list.append(2);
	list.read();
	list.read();
	list.removeLastRead();
	list.resetRead();
	assert(*(list.read()) == 0);
	assert(*(list.read()) == 2);
	assert(list.count == 2);
	list.removeFirst();
	list.resetRead();
	assert(*(list.read()) == 2);
	assert(list.count == 1);
	list.removeLastRead();
	assert(list.count == 0);
	//`LinkedList.toArray` and `LinkedList.insertNode` and `LinkedList.insertNodes`
	list.clear();// to reset stuff
	list.append(0);
	list.append(4);
	list.read();
	list.insert(1);
	assert(*(list.read()) == 1);
	list.insert([2, 3]);
	list.resetRead();
	assert(list.count == 5);
	assert(list.toArray == [0, 1, 2, 3, 4]);
	//`Linkedlist.hasElement` and `LinkedList.hasElements`
	assert(list.hasElement(0) == true);
	assert(list.hasElement(4) == true);
	assert(list.hasElement(5) == false);
	assert(list.hasElement(7) == false);
	assert(list.hasElements([3, 1, 2, 0, 4]) == true);
	assert(list.hasElements([0, 1, 2, 6]) == false);
	// `LinkedList.insert` at beginning
	list.clear;
	list.insert([1, 2]);
	list.insert(0);
	assert(list.count == 3);
	assert(list.toArray == [0, 1, 2]);
	//destroying last item
	list.clear();
	list.append(0);
	list.append(1);
	list.append(2);
	list.read();
	list.read();
	list.read();
	assert(list.removeLastRead() == true);
	assert(list.toArray() == [0, 1]);
	//bookmarks
	list.clear;
	list.append([0, 1, 2, 3, 4, 5]);
	assert(*list.read == 0);
	assert(*list.read == 1);
	assert(*list.read == 2);
	{
		uinteger id = list.placeBookmark;
		assert(*list.read == 3);
		assert(list.moveToBookmark(id + 1) == false);
		assert(list.moveToBookmark(id) == true);
		assert(*list.read == 3);
		assert(list.removeBookmark(id) == true);
	}
	// now to test LinkedList.remove
	list.clear;
	list.append([0,0,1,1,2,3,3,4,5,6,0,0]);
	assert(list.remove(0,2) == true);
	assert(list.toArray == [1,1,2,3,3,4,5,6,0,0], to!string(list.toArray));
	assert(list.remove(0) == true);
	assert(list.toArray == [1,1,2,3,3,4,5,6]);
	assert(list.remove([1,3]) == true);
	assert(list.toArray == [2,4,5,6]);
	destroy(list);
}

/// Used in log display widgets (like in dub package `qui` `qui.widgets.LogWidget`)
/// 
/// Holds up to a certain number of items, after which it starts over-writing older ones
deprecated class LogList(T){
private:
	List!T list;
	uinteger readFrom, maxLen;
public:
	this(uinteger maxLength=100){
		list = new List!T;
		readFrom = 0;
		maxLen = maxLength;
	}
	~this(){
		delete list;
	}
	/// adds an item to the log
	void add(T dat){
		if (list.length>=maxLen){
			list.set(readFrom,dat);
			readFrom++;
		}else{
			list.add(dat);
		}
	}
	/// Returns: array containing items
	T[] read(uinteger count=0){
		T[] r;
		if (count>list.length){
			count = list.length;
		}
		if (count > 0){
			uinteger i;
			if (count>list.length){
				count = list.length;
			}
			r.length = count;
			for (i = readFrom; i < count; i++){
				r[i] = list.read((readFrom+i)%count);
			}
		}else{
			r = null;
		}
		return r;
	}
	/// resets and clears the log
	void reset(){
		list.clear;
		readFrom = 0;
	}
	/// Returns: the max number of items that can be stored
	@property uinteger maxCapacity(){
		return maxLen;
	}
}

/// TODO: do something about this
/// For reading large files which otherwise, would take too much memory
/// 
/// Aside from reading, it can also write to files. TODO make it ready
/*class FileReader{
private:
	File file; /// the file currently loaded
	bool closeOnDestroy; /// stores if the file will be closed when this object is destroyed
	uinteger _minSeek; /// stores the minimum value of seek, if zero, it has no effect
	uinteger _maxSeek; /// stores the maximum value of seek, if zero, it has no effect
	uinteger _maxSize; /// stores the max size of the file in case _minSeek and _maxSeek are set non-zero
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
	this (File f, uinteger minSeek, uinteger maxSeek){
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
	bool lock(uinteger start, uinteger length){
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
	void unlock (uinteger start, uinteger length){
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
	ubyte[] read (uinteger n){
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
	bool remove (uinteger index, uinteger length){
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
	bool truncate(uinteger newSize, bool onFailTrySlow=false){
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
				uinteger oldSeek = this.seek;
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
	import std.conv : to;
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
	assert (fread.read(cast(uinteger)5) == [8,7,6,5,4]);
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
class ByteStream{
private:
	ubyte[] _stream;
	uinteger _seek;
	bool _grow;
	uinteger _maxSize;
	union ByteUnion(T){
		T data;
		ubyte[T.sizeof] array;
	}
public:
	/// constructor
	/// 
	/// `grow` is whether the stream is allowed to grow in size while writing  
	/// `maxSize` is the maximum size stream is allowed to grow to (0 for no limit)
	this(bool grow = true, uinteger maxSize = 0){
		_grow = grow;
		_maxSize = maxSize;
	}
	~this(){
		.destroy(_stream);
	}
	/// Seek position (i.e: next read/write index)
	@property uinteger seek(){
		return _seek;
	}
	/// ditto
	@property uinteger seek(uinteger newVal){
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
	/// This is only enforced while writing
	@property uinteger maxSize(){
		return _maxSize;
	}
	/// ditto
	@property uinteger maxSize(uinteger newVal){
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
	@property uinteger size(){
		return _stream.length;
	}
	/// Reads a slice from the stream into buffer. Will read number of bytes so as to fill `buffer`
	/// 
	/// Returns: number of bytes read
	uinteger readRaw(ubyte[] buffer){
		immutable uinteger len = _seek + buffer.length > _stream.length ? _stream.length - _seek : buffer.length;
		buffer[0 .. len] = _stream[_seek .. _seek + len];
		_seek += len;
		return len;
	}
	/// Reads a data type T from current seek. **Do not use this for reading arrays**
	///
	/// Will return invalid data if there are insufficient bytes to read from.  
	/// If value of `n` is non-zero, that number of bytes will be read.
	/// 
	/// Returns: the read data
	T read(T)(ubyte n=0){
		ByteUnion!T u;
		if (n == 0 || n > T.sizeof)
			read(u.array);
		else
			read(u.array[0 .. n]);
		_seek += n == 0 ? T.sizeof : n;
		return u.data;
	}
	/// Reads an array.
	/// 
	/// in case of insufficient bytes in stream, will return array of correct length but missing bytes at end.  
	/// `n` is the number of bytes to read for length of array, default(`0`) is `size_t.sizeof`
	/// 
	/// Returns: the read array
	T[] readArray(T)(ubyte n=0){
		T[] r;
		r.length = read!uinteger(n); // length
		readRaw(r); // then array itself
		return r;
	}
	/// Writes data at seek. **Do not use this for arrays**
	/// 
	/// `n` is number of bytes to actually write, default (0) is `T.sizeof`
	/// 
	/// Returns: true if written, false if not (could be because stream not allowed to grow, or max size reached)
	bool write(T)(T data, ubyte n=0){
		ByteUnion!T u;
		u.data = data;
		immutable uinteger newSize = _seek + (n == 0 ? u.array.length : n); // size after writing
		if (newSize > _stream.length){
			if (!_grow || (_maxSize && newSize > _maxSize))
				return false;
			_stream.length = newSize;
		}
		if (n == 0 || n > u.array.length){
			_stream[_seek .. _seek + u.array.length] = u.array;
			_seek += u.array.length;
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
	uinteger writeRaw(T)(T[] data){
		uinteger len = data.length;
		if (_seek + len > _stream.length){
			if (!_grow)
				len = _stream.length - _seek;
			else if (_maxSize && _seek + len > _maxSize)
				len = _maxSize - _seek;
			_stream.length = _seek + len;
		}
		_stream[_seek .. _seek + (len * T.sizeof)] = (cast(ubyte*)data.ptr)[0 .. len * T.sizeof];
		_seek += len;
		return len;
	}
	/// Writes an array at seek.
	/// 
	/// `n` is the number of bytes to use for storing length of array, default (`0`) is `size_t.sizeof`
	/// 
	/// Returns: true if written, false if not (due to maxSize reached or not allowed to grow)
	bool writeArray(T)(T[] data, ubyte n=0){
		immutable uinteger newSize = _seek + (n == 0 ? uinteger.sizeof : n) + (data.length * T.sizeof);
		if (newSize > _stream.length){
			if (!_grow || (_maxSize && newSize > _maxSize))
				return false;
			_stream.length = newSize;
		}
		if (this.write(data.length, n)){
			return writeRaw(data) == data.length * T.sizeof;
		}
		return false; // something bad went wrong, while writing size
	}
}
/// 
unittest{

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
	uinteger count(){
		// stores the count
		uinteger r = 0;
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
	uinteger count(bool function(TreeNode!(T)*) doCount=null){
		/// stores the count
		uinteger r = 0;
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
