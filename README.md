# utils
Some misc. functions and classes for D, that I frequently use in my other packages.  
All of the code is commented well enough, and you can use ddoc to generate documentation.

---

## `utils.baseconv`
A module contaning some functions to convert between Hex, Binary, and Denary.  

---

## `utils.lists`
Contains classes related to arrays. It includes:

* `List` - to store data in dynamic arrays where length will be varying very often.
* `Stack` - A linked list based stack.
* `FIFOStack` - Same as `Stack` but FIFO.
* `ExtraAlloc` - A class to manage keeping extra instances of classes or whatever.
* `LinkedList` - A linked list
* `LogList` - I wouldn't use it, its code hasnt been touched in long time
* `FileReader` - commented out, I forgot why I was working on this.
* `TreeNode` - Idk why I made this, but use it with `TreeReader` struct and the iterate function might be useful. Nothing special.

---

## `utils.misc`
Contains some misc. functions, mostly for dealing with dynamic arrays
