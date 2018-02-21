/++
	This module contains classes that are related to data storage
+/
module utils.lists;

import std.file;
import std.stdio;
import utils.misc;

/// Use to manage dynamic arrays that frequently change lengths
/// 
/// Provides more functionality for arrays, like searching in arrays, removing elements...
class List(T){
private:
	T[] list;
	uinteger taken=0;
	uinteger extraAlloc;
public:
	/// constructor
	/// 
	/// extraCount is the number of extra space to make for new elements when making "room" for new elements
	this(uinteger extraCount = 4){
		extraAlloc = extraCount;
	}
	/// appends an element to the list
	void add(T dat){
		if (taken==list.length){
			list.length+=extraAlloc;
		}
		taken++;
		list[taken-1] = dat;
	}
	/// appends an array to the list
	void addArray(T[] dat){
		list.length = taken;
		list ~= dat;
		taken += dat.length;
	}
	/// Changes the value of element at an index.
	/// 
	/// `dat` is the new data
	void set(uinteger index, T dat){
		list[index]=dat;
	}
	/// Removes last elements(s) starting from an index; number of elements to remove is in `count`
	void remove(uinteger index, uinteger count=1){
		integer i;
		integer till=taken-count;
		for (i=index;i<till;i++){
			list[i] = list[i+count];
		}
		list.length-=count;
		taken-=count;
	}
	/// Removes last elements(s); number of elements to remove is in `count`
	void removeLast(uinteger count = 1){
		taken -= count;
		if (list.length-taken>extraAlloc){
			list.length=taken;
		}
	}
	/// shrinks the size of the list, removing last elements.
	void shrink(uinteger newSize){
		if (newSize < taken){
			list.length=newSize;
			taken = list.length;
		}
	}
	/// Inserts an array into this list
	void insert(uinteger index, T[] dat){
		integer i;
		T[] ar,ar2;
		ar=list[0..index];
		ar2=list[index..taken];
		list.length=0;
		list=ar~dat~ar2;
		taken+=dat.length;
	}
	/// Inserts an element into this list
	void insert(uinteger index, T dat){
		integer i;
		T[] ar,ar2;
		ar=list[0..index];
		ar2=list[index..taken];
		list=(ar~[dat]~ar2).dup;
		taken++;
	}
	/// Writes the list to a file.
	/// 
	/// `sp` is the line separator. In case of strings, you want it to be `"\n"`;
	void saveFile(string s, T sp){
		File f = File(s,"w");
		uinteger i;
		for (i=0;i<taken;i++){
			f.write(list[i],sp);
		}
		f.close;
	}
	/// Reads an element at an index
	T read(uinteger index){
		return list[index];
	}
	/// Read a slice from the list.
	/// 
	/// The slice is copied to avoid data in list from getting changed
	T[] readRange(uinteger index,uinteger i2){
		T[] r;
		r = list[index .. i2].dup;
		return r;
	}
	/// Reads the last element in list.
	T readLast(){
		return list[taken-1];
	}
	/// returns last elements in list. number of elements to return is specified in `count`
	T[] readLast(uinteger count){
		T[] r;
		r = list[taken-count..taken].dup;
		return r;
	}
	/// length of the list
	@property integer length(){
		return taken;
	}
	/// Exports this list into a array
	T[] toArray(){
		return list.dup;
	}
	/// Loads array into this list
	void loadArray(T[] newList){
		uinteger i;
		list = newList.dup;
		taken = newList.length;
	}
	/// empties the list
	void clear(){
		list = [];
		taken = 0;
	}
	/// Returns index of the first matching element. -1 if not found
	/// 
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
/// Unittest for List
unittest{
	List!ubyte list = new List!ubyte;
	//`List.insert` and `List.add` and `List.toArray`
	list.add(0);
	list.add(1);
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
	list.addArray([4, 5, 6, 7, 8]);
	assert(list.length == 9);
	//`List.set` and `List.read`
	list.set(0, 1);
	assert(list.read(0) == 1);
	//`List.readLast`
	assert(list.readLast() == 8);
	assert(list.readLast(2) == [7, 8]);
	//`List.readRange`
	assert(list.readRange(0, 2) == [1, 1]);
	//`List.remove`
	list.remove(0, 2);
	assert(list.read(0) == 2);
	//`List.removeLast`
	list.removeLast(2);
	assert(list.readLast() == 6);

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
	/// Reads and removes an item from the stack, if no more items are present, throws Exception
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
	/// if not enough items are left, throws Exception
	/// 
	/// count is the number of elements to return
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
	/// Empties the stack
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
/// Unittests for Stack
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
	///clears/resets the list. Frees all the occupied memory, & removes all items
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
	///adds a new node at the end of the list
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
	///adds new nodes at end of list from an array
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
	///removes the first node in list
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
	///removes the node that was last read using `LinkedList.read`. The last node cannot be removed using this.
	///returns true on success
	///
	///It works by moving contents of next item into the last-read one, and removing the next node
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
		}
		//decrease count
		if (r){
			itemCount --;
			//since the last-read has been removed, null that pointer, to prevent segFault
			lastReadPtr = null;

		}
		return r;
	}
	///number of items that the list is holding
	@property uinteger count(){
		return itemCount;
	}
	///resets the read position, i.e: set reading position to first node, and nulls the last-read-ptr
	void resetRead(){
		nextReadPtr = firstItemPtr;
		lastReadPtr = null;
	}
	///returns pointer of next node to be read, null if there are no more nodes
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
	/// Returns the pointer to the first node in the list
	T* readFirst(){
		if (firstItemPtr !is null){
			lastReadPtr = firstItemPtr;
			return &((*firstItemPtr).data);
		}else{
			return null;
		}
	}
	/// Returns the pointer to the last node in the list
	T* readLast(){
		if (lastItemPtr !is null){
			lastReadPtr = lastItemPtr;
			return &((*lastItemPtr).data);
		}else{
			return null;
		}
	}
	/// Reads the list into an array, and returns the array
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
	/// Inserts a node after the position of last-read-node
	/// To insert at beginning, call `resetRead` before inserting
	/// 
	/// For inserting more than one nodes, use `LinkedList.insertNodes`
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
	/// Inserts an array of nodes after the position of last-read-node
	/// If there is no last-read-item, the item is inserted at beginning. To do this, call `resetRead` before inserting
	/// Returns true on success, false on failure
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
	/// Returns true if list contains a node, i.e searches for a node and returns true if found
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
	/// Returns true if list contains all elements provided in an array, else, false
	/// 
	/// returns false if the array contains the same elements at more than one index
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
	/// Sets a "bookmark", and returns the bookmark-ID, throws Exception if there is no last-read-item to place bookmark on
	/// 
	/// this ID can later be used to go back to the reading position at which the bookmark was placed
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
	/// moves read/insert position back to a bookmark using the bookmark ID
	/// Does NOT delete the bookmark. Use `LinkedList.removeBookmark` to delete
	/// Retutns true if successful
	/// false if the bookmark ID no longer exists
	bool moveToBookmark(uinteger id){
		if (id !in bookmarks){
			return false;
		}else{
			nextReadPtr = bookmarks[id];
			return true;
		}
	}
	/// removes a bookmark using the bookmark id
	/// returns true if successful
	/// false if the bookmark doesn't exist
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
/// Unittests for `utils.lists.LinkedList`
unittest{
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
	destroy(list);
}

/// Used in logging widgets. Holds upto certain number of elements, after which older elements are over-written
class LogList(T){
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
	///adds an item to the log
	void add(T dat){
		if (list.length>=maxLen){
			list.set(readFrom,dat);
			readFrom++;
		}else{
			list.add(dat);
		}
	}
	///Returns array containing items, in first-added-last order
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
	///resets and clears the log
	void reset(){
		list.clear;
		readFrom = 0;
	}
	///returns the max number of items that can be stored
	@property uinteger maxCapacity(){
		return maxLen;
	}
}

/// For reading files. Can also be used for writing
class FileReader{
private:
	ubyte[] stream = null;
	uinteger seekPos = 0;
public:
	/// If filename is not null, attempts to load file into memory
	this(string filename=null){
		if (filename != null){
			this.loadFile(filename);
		}
	}
	~this(){
		// destructor, nothing to do yet
	}
	/// loads file into memory, throws exception if fails
	void loadFile(string filename){
		stream = cast(ubyte[])std.file.read(filename);
		seekPos = 0;
	}
	/// Writes the stream to a file, throws exception if fails
	void saveFile(string filename){
		std.file.write(filename, cast(void[])stream.dup);
	}

	/// reads and returns `size` number of bytes from file starting from seek-position
	/// If not enough bytes are left, the array returned will be smaller than `size`
	/// Returns null if the seek-position is at end, or if there are no bytes to be read
	void[] read(uinteger size=1){
		// check if `size` number of chars are left
		if (size + seekPos <= stream.length){
			void[] r = stream[seekPos .. seekPos+size].dup;
			seekPos += size;
			return r;
		}else if (seekPos < stream.length){
			void[] r = stream[seekPos .. stream.length].dup;
			seekPos = stream.length;
			return r;
		}else{
			// nothing left to read, return null
			return null;
		}
	}
	/// Reads and returns bytes starting from seek till `terminate` byte, or if EOF is reached
	void[] read(ubyte terminate){
		uinteger readFrom = seekPos;
		while (seekPos < stream.length){
			if (stream[seekPos] == terminate){
				seekPos ++;// to include the terminate byte in result
				break;
			}
			seekPos ++;
		}
		return stream[readFrom .. seekPos].dup;
	}
	/// Writes an array at the seek-position, and moves seek to end of the written data
	void write(ubyte[] t){
		if (seekPos > stream.length){
			throw new Exception("failed to write data to stream. Seek is out of stream.length");
		}else if (seekPos == stream.length){
			// just append to end of stream
			stream = stream ~ t.dup;
			seekPos = stream.length;
		}else{
			// insert it in the middle
			stream = stream[0 .. seekPos] ~ t ~ stream[seekPos .. stream.length];
			seekPos += t.length;
		}
	}
	/// Writes a byte at the seek-position, and moves seek to end of the written data
	void write(ubyte t){
		write([t]);
	}
	/// Removes a number of bytes starting from the seek-position
	/// 
	/// Returns true if it was able to remove some bytes, false if not
	bool remove(uinteger count = 1){
		// make sure there are enough bytes to remove
		if (seekPos + count > stream.length){
			// remove as much as possible
			if (seekPos >= stream.length){
				return false;
			}else{
				stream = stream[0 .. seekPos-1];
			}
		}else{
			stream = stream[0 .. seekPos-1] ~ stream[seekPos + count .. stream.length];
		}
		return true;
	}
	/// Clears the stream, resets the stream
	void clear(){
		stream.length = 0;
		seekPos = 0;
	}
	/// The seek position, from where the next char(s) will be read, or written to
	@property uinteger seek(){
		return seekPos;
	}
	/// The seek position, from where the next char(s) will be read, or written to
	@property uinteger seek(uinteger newSeek){
		if (newSeek > stream.length){
			return seekPos = stream.length;
		}else{
			return seekPos = newSeek;
		}
	}
	/// The size of file in bytes, read-only
	@property uinteger size(){
		return stream.length;
	}
}
/// unittests for FileReader
unittest{
	// file loading/ saving not tested
	FileReader stream = new FileReader();
	assert(stream.seek == 0);
	// write & read
	stream.write(cast(ubyte[])"ABCE");
	assert(stream.seek == 4);
	assert(stream.size == 4);
	stream.seek = 3;
	stream.write(cast(ubyte)'D');
	assert(stream.size == 5);
	assert(stream.seek == 4);
	stream.seek = 0;
	assert(stream.read(stream.size) == cast(ubyte[])"ABCDE");
	stream.seek = 0;
	assert(stream.read(cast(ubyte)'C') == cast(ubyte[])"ABC");
	stream.seek = 0;
	assert(stream.read(cast(ubyte)'Z') == cast(ubyte[])"ABCDE");
	// clear
	stream.clear;
	assert(stream.size == 0);
	assert(stream.seek == 0);
	// remove
	stream.write(cast(ubyte[])"ABCDE");
	stream.seek = 3;
	assert(stream.remove(99) == true);
	stream.seek = 0;
	assert(stream.read(cast(ubyte)'Z') == cast(ubyte[])"AB");
	stream.write(cast(ubyte[])"CDE");
	stream.seek = 1;
	assert(stream.remove(2) == true);
	stream.seek = 0;
	assert(stream.read(cast(ubyte)'Z') == "DE");
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
/// unittests for TreeReader
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
