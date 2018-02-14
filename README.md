# utils
Some misc. functions and classes for D, that I frequently use in my other packages

---

## `utils.baseconv`
A module contaning some functions to convert between Hex, Binary, and Denary  

---

## `utils.lists`
Contains classes related to arrays. It includes:
* `List` - to store data in dynamic arrays where length will be varying very often.
* `LinkedList` - a Linked List implementation with search (`hasElement`), and "bookmarks"
* `Stack` - a stack implementation, especially designed for use in QScript. Works similar to Linked List, not using dynamic arrays
* `LogList` - used in qui's LogWidget, used to store "logs" for displaying, in a way that older logs are over-written, as they wont be displayed. For storing the actual logs, use some other list.
* `FileReader` - a (useless) file reader, but I needed this for some project of mine, where I had to read number of bytes from in-between files.
* `TreeNode` and `TreeReader` - used to store and read a Tree, but doesnt allow "loops" inside the tree (a child node cannot have a parent node, or parent's parent node.. as its child)

---

## `utils.misc`
Contains some misc. functions, mostly for dealing with dynamic arrays
