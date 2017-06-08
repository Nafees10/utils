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
public:
	/// appends an element to the list
	void add(T dat){
		if (taken==list.length){
			list.length+=10;
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
		if (list.length-taken>10){
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
		list.length=0;
		list=ar~[dat]~ar2;
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
		r.length = (i2-index);
		r[0 .. r.length] = list[index .. i2];
		return r;
	}
	/// Reads the last element in list.
	T readLast(){
		return list[taken-1];
	}
	/// returns last elements in list. number of elements to return is specified in `count`
	T[] readLast(uinteger count){
		T[] r;
		r.length = count;
		r[0 .. r.length] = list[taken-count..taken];
		return r;
	}
	/// length of the list
	@property integer length(){
		return taken;
	}
	/// Exports this list into a array
	T[] toArray(){
		uinteger i;
		T[] r;
		if (taken!=-1){
			r.length=taken;
			for (i=0;i<taken;i++){//using a loop cuz simple '=' will just copy the pionter
				r[i]=list[i];
			}
		}
		return r;
	}
	/// Loads array into this list
	void loadArray(T[] dats){
		uinteger i;
		list.length=dats.length;
		taken=list.length;
		for (i=0;i<dats.length;i++){
			list[i]=dats[i];
		}
	}
	/// empties the list
	void clear(){
		list.length=0;
		taken=0;
	}
	/// Returns index of the first matching element. -1 if not found
	/// 
	/// `dat` is the element to search for
	/// `i` is the index from where to start, default is 0
	/// `forward` if true, searches in a forward direction, from lower index to higher
	integer indexOf(T dat, integer i=0, bool forward=true){
		if (forward){
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
}

/// A basic stack
/// It has a max-size defined in the constructor
class Stack(T){
private:
	T[] list;
	uinteger pos = 0;
public:
	this(uinteger size=512){
		list = new T[size];
	}
	~this(){
		delete list;
	}
	/// Appends an item to the stack
	void push(T dat){
		pos ++;
		list[pos] = dat;
	}
	/// Appends an array of items to the stack
	void push(T[] dat){
		pos++;
		list[pos..pos+dat.length] = dat;
		pos += dat.length-1;
	}
	/// Reads and removes an item from the stack
	T pop(){
		T r;
		r = list[pos];
		pos--;
		return r;
	}
	/// Reads an removes an array of items from the stack
	T[] pop(uinteger count){
		T[] r;
		r.length = count;
		r[0..count] = list[(pos - count)+1..pos+1];
		pos -= count;
		return r;
	}
	/// Empties the stack
	void clear(){
		pos = 0;
	}
	/// the position from which the next item will be read, or added
	@property uinteger position(){
		return pos;
	}
	/// the position from which the next item will be read, or added
	@property uinteger position(uinteger newPos){
		return pos=newPos;
	}
}
/// Unittests for Stack
unittest{
	Stack!ubyte stack = new Stack!ubyte;
	//`Stack.push` and `Stack.pop`
	stack.push(0);
	stack.push([1, 2]);
	assert(stack.pop == 2);
	assert(stack.pop(2) == [0, 1]);
	//`Stack.clear`
	stack.push(0);
	stack.clear;
	assert(stack.position == 0);
	//`Stack.position`
	stack.push([0, 1, 2]);
	stack.position = 1;
	assert(stack.pop == 0);
}

///represents an item in a linked list. contains the item, and pointer to the next item's container
private struct LinkedItem(T){
	T data;
	LinkedItem!(T)* next = null;//mark it null to show the list has ended
}
/// A linked list, used where only reading in the forward direction is required
class LinkedList(T){
private:
	LinkedItem!(T)* firstItemPtr;
	LinkedItem!(T)* lastItemPtr;//the pointer of the last item, used for appending new items
	LinkedItem!(T)* nextReadPtr;//the pointer of the next item to be read
	LinkedItem!(T)* lastReadPtr;//the pointer to the last item that was read

	uinteger itemCount;//stores the total number of items
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
				// decrease count
				itemCount --;
				r = true;
			}else{
				// if there is only one item, then it can be deleted
				if (itemCount == 1){
					// just clearing the list will do the job
					this.clear();
				}
				r = true;
			}
		}
		return r;
	}
	///number of items that the list is holding
	@property uinteger count(){
		return itemCount;
	}
	///resets the read position, i.e: set reading position to first node
	void resetRead(){
		nextReadPtr = firstItemPtr;
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
			return &((*firstItemPtr).data);
		}else{
			return null;
		}
	}
	/// Returns the pointer to the last node in the list
	T* readLast(){
		if (lastItemPtr !is null){
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
	/// Returns true on success, false on failure
	/// 
	/// For inserting more than one nodes, use `LinkedList.insertNodes`
	bool insertNode(T node){
		//make sure that there was a node that was last-read
		if (lastReadPtr !is null){
			LinkedItem!(T)* newNode = new LinkedItem!T;
			(*newNode).data = node;
			// make new node point to the current next-to-be-read node
			(*newNode).next = lastReadPtr.next;
			// make last read node point to new node
			(*lastReadPtr).next = newNode;

			return true;
		}else{
			return false;
		}
	}
	/// Inserts an array of nodes after the position of last-read-node
	/// Returns true on success, false on failure
	bool insertNodes(T[] nodes){
		if (lastReadPtr !is null && nodes.length > 0){
			LinkedItem!(T)*[] newNodes;
			newNodes.length = nodes.length;
			// put nodes inside the LinkedItem list
			for (uinteger i = 0, lastIndex = nodes.length-1; i < nodes.length; i++){
				newNodes[i] = new LinkedItem!T;
				(*newNodes[i]).data = nodes[i];
				// make them point to next item
				if (i < lastIndex){
					(*newNodes[i]).next = newNodes[i + 1];
				}
			}
			// and make the last node in list point to the node after last-read
			(*newNodes[newNodes.length-1]).next = (*lastReadPtr).next;
			// make last read node point to the first new-node
			(*lastReadPtr).next = newNodes[0];

			return true;
		}else{
			return false;
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
	/// Returns true if list contains all elements provided in an array
	/// 
	/// It will fail if the array contains the same elements at more than one index
	bool hasElements(T[] nodes){
		bool r = false;
		// go through the list and match as many elements as possible
		LinkedItem!(T)* currentNode = firstItemPtr;
		while (currentNode !is null){
			// check if current node matches any in array
			integer index = nodes.indexOf((*currentNode).data);
			if (index >= 0){
				// this node matched, so remove it from the array
				nodes = nodes.deleteElement(index);
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