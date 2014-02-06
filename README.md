***EXPERIMENTAL***

Smith is a dynamic object-oriented language compiling to JavaScript.

Features
---
- Boring syntax
- Types
- Reified classes and meta-classes
- Reified documentation
- Easier module system with customizable auto-imports

Build
---
* Get [node.js](http://nodejs.org/download).
* `git clone https://github.com/andy-hanson/smith.git; cd smith; ./build`

Edit
---
If you have Sublime Text 3, run `cake install-sublime-files` from the command prompt and it will be installed for you.
Then just open a `.smith` file and select `View->Syntax->User->Smith`.

Call Methods
---
	\ I'm a comment.
	val three
		val two
			2
		two.+ 1

First we define a local value named `three`.
It will be set to the value of the last line in its indented block.
Note that `two` only accessible within that block.

In this case, the *object* `two`'s *method* `plus` is called on the *argument* `1`.

If you leave off the method name, it is `of`.  For example:

	! (1.< 2) \ In other words, !.of (1.< 2)

`!`'s static method `of` asserts a condition.
If you want to call a method and then call `of` on the result, the preferred style is like so:

	\ Gets the third element of the list
	(the.list) 3 \ Preferred over the.list.of 3

Watch out: `a.b c.d e` sends two arguments to `a.b` and none to `c.d`.

Define Methods
---

	$$ twice a
		a.* 2

Methods beginning with `$` are parsed specially. The above is equivalent to:

	me.$$ "twice" |a \ '|' opens a function
		a.* 2

Either way, it defines a new static method `twice` on `me`.

	twice 3 \ 6

Methods without an object are always called on `me`.
`me` is the current object. If this file is named `Hello-World.smith`, then `me` is the `Hello-World` class.

If `twice` was a local, this code would mean `twice.of 3`. Don't get them confused!

Make Funs
---

If a `Fun` has no arguments, *you just have to indent*.

	(1.< 2).if!
		Console.log! "Still sane!"

If it does, just use a `|` on the line preceding the indented block.

	val list
		List 1 2 3
	list.map |list-element
		twice list-element
	\ 2, 4, 6

Unlike in JavaScript, *`me` is preserved inside a Fun*. (But some methods undo this by calling `fun.un-bound`).

You could just say:

	list.map
		twice it

`it` is an implicit first argument.
Or you could say:

	list.map twice_

A name ending in `_` is bound to `me`. You can bind to other objects like:

	list.each Console.log!_ \ Prints 1 2 3 each on their own line

As it turns out, there is already a doubling method. You could call it like so:

	list.map
		it.

Or just:

	list.map _twice

A name beginning in `_` is called an 'it-method'.
The second, third, and so on arguments become the arguments to the call, while the first becomes the subject.
So you can also say:

	list.fold _+ \ 6

If you have two Funs in a row, the second `|` is mandatory.
For example (`?` implements an *if-then-else* expression):

	(1.< 2).?
		"Still sane"
	|
		"Not feelin' so good"

Types
---
You can specify argument types, return types, and value types.

	val six:Nat \ value type
		(List 1 2 3).fold |:Nat x:Nat y:Nat \ return type and argument types
			x.+ y

	$$ twice:Nat a:Nat \ again, return type and argument types
		a.* 2

A runtime error is thrown if an object is not of the expected type.
By the way, types are not classes. `Real` is the class of numbers, and `Nat` is a type that checks for `Real`s like 0, 1, 2, etc.

Modules
---
***DESCRIBE ME***
`use` vs `use!`
`modules` files
	`auto` `auto!`
`export`

Classes
---

***DESCRIBE ME***
Static methods
Instance methods
Inheritance (super, trait)


Meta
---

Let's write a better twice.

	$$ better-twice n:Nat
		doc
			Product of all numbers 1 to `n`.
		in
			\ '!' asserts that its argument is `true`.
			! (n.= 333).not \ I refuse to double this number.
		out
			res.divisible? n
		eg
			!= 6
				better-twice 3
		how
			Turns out someone wrote it for me.
		oth
			Put any other meta-info here.
			version
				0.0.0
			author
				Andy
			listening-to
				Gossippo Perpetuo

		n.twice

All of this information (save for `in` and `out`) goes into a `Meta` object accessed via `fun.meta`.

`doc`, `how`, and `oth` simply bring a block of text into the `Meta`.

`in`, `out`, and `eg` all happen in different contexts:

* `in` has access to all arguments and runs before the body.
* `out` has access to all arguments and runs after the body.
* `eg` has the same scope and same `me` as outside of the Fun.

Quotes
---

***DESCRIBE ME***

Optional and Splat Arguments
---

***DESCRIBE ME***

Standard classes of import
---
I recommend you look at the documentation *(CURRENTLY NONEXISTENT)* of these classes:

	! (and !=)
	Any-Class
	Bool
	Ref
	Str
	Meta

	Collection
	Iterable
	Bag
	List
	Array

	MORE

JavaScript compatibility
---
In Smith, `.` always means a method call.
To access a property, use `@`, as in `array@length` (or just use `array.size`).

To pass through JavaScript directly, use a \`-indented block:

	`
		I'm JavaScript.

Or just pass through an expression:
	`1 + 1`.twice \ Parentheses added


Known Bugs
---
Segfaults randomly D:

License
---
DO WHATEVER THE FUCK YOU WANT, PUBLIC LICENSE
TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION

0. You just DO WHATEVER THE FUCK YOU WANT.
