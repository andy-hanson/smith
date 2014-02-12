***EXPERIMENTAL***

Smith is a dynamic object-oriented language compiling to JavaScript. It's also a work-in-progress and suggestions are welcome.

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

Edit Code
---
If you have Sublime Text 3, run `cake install-sublime-files` from the command prompt and it will be installed for you.
Then just open a `.smith` file and select `View->Syntax->User->Smith`.
Currently you must write code within the provided 'source' directory. Use 'cake run' to run it.

Call Methods
---
	\ I'm a comment.
	val three
		val two
			2
		two.+ 1

First we define a local value named `three`.
It will be set to the value of the last line in its indented block.
Note that `two` is only accessible within that block.

Some terminology: The *object* `two`'s *method* `plus` is *called* on the *argument* `1`.
The result is *returned* from the *block* and becomes the *value* of the *local variable* `three`.
(In Smith, all *values* are *objects*.)

If you leave off the method name, it is `of`.  For example:

	! (1.< 2) \ In other words, !.of (1.< 2)

`!`'s static method `of` asserts a condition.
If you want to call a method and then call `of` on the result, the preferred style is like so:

	\ Gets the third element of the list
	(the.list) 3 \ Preferred over the.list.of 3

Watch out: `a.b c.d e` sends two arguments to `a.b` and none to `c.d`. Nested calls always require parentheses, as in `a.b (c.d e)`.

Define Methods
---

	$$ twice a
		a.* 2

Methods beginning with `$` are parsed specially. The above is equivalent to:

	me.$$ "twice" |a \ '|' opens a function
		a.* 2

Either way, it defines a new static method `twice` on `me`. Let's call it.

	twice 3 \ 6

Methods without an object are always called on `me`, the current object. If this file is named `Hello-World.smith`, then `me` is the `Hello-World` class.

If `twice` was a local, this code would mean `twice.of 3`. If you have a method `get-my-list` and you want its third element, use `(get-my-list) 3`.

Make Funs
---

If a `Fun` has no arguments, you just have to indent.

	(1.< 2).if!
		Console.log! "Still sane!"

If it has arguments, use a `|` on the line preceding the indented block.

	val list
		List 1 2 3
	list.map |list-element
		twice list-element
	\ 2, 4, 6

Unlike in JavaScript, **`me` is preserved inside a Fun**. (But some methods undo this by calling `fun.un-bound`).

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
		it.twice

Or just:

	list.map _twice

A name beginning in `_` is called an 'it-method'.
The second, third, and so on arguments become the arguments to the call, while the first becomes the subject.
So you can also say:

	list.fold _+ \ 6

If you have two Funs in a row, the second `|` is mandatory.
For example: (`?` implements an *if-then-else* expression)

	val status
		(1.< 2).?
			"Still sane"
		|
			"Not feelin' so good"

Types
---
You can specify value types, return types, and argument types.

	val six:Nat \ Value type.
		(List 1 2 3).fold |:Nat x:Nat y:Nat \ Return type and argument types.
			x.+ y

	$$ twice:Nat a:Nat \ Using special $ syntax, it's as if a '|' is immediately after 'twice'.
		a.* 2

A runtime error is thrown if an object is not of the expected type.
(By the way, types are not always classes. `Real` is the class of numbers, and `Nat` is a type that checks for `Real`s like 0, 1, 2, etc.)

Modules
---

Here we use a module:

	use Loop
	Loop.times 3
		Console.log! "And around we go again!"

The `use` statement lazily loads the module `Loop` and stores it in a variable also named `Loop`.
Laziness is useful: it allows two modules to refer to each other.
If you need a module for a side effect, use `use!`.

All files start off inside a class. If you want your module to be something else, use `export`.

Okay, but where does the module `Loop` come from? If it's in the same directory you don't need to do anything.
If it's from somewhere more complicated, rather than store that information in a source file, your code directory should contain a special file named `modules`.

Here's a sample: ***Module syntax not fully implemented!***

	\ I am called 'modules'

	\ All source files in this directory automatically use 'Console'. (Use 'auto' sparingly!)
	auto Console
	\ This could be a relative to the 'modules' file, or just something we expect in node_modules
	Standard smith-standard
	\ The module contains multiple components as methods in its index.
	Console Loop from Standard

Here's how we use these:

	use Standard \ New local 'Standard' is require('smith-standard')
	use Loop \ New local 'Loop' is require('smith-standard').Loop()
	Console.log! "Console is used automatically"

Classes
---

We've all along been adding static methods to our class 'Hello-World'.
Let's write a class with actual *instances*.

	\ Counter.smith
	eg \ This block defines an example; see the 'Meta' section.
		val monte-cristo
			Counter 0
		monte-cristo.increment!
		!= 1
			monte-cristo.count
		monte-cristo.decrement!
		!= 0
			monte-cristo.count

	data |-amount!:Num
		Console.log! "Constructing a Counter starting at {-amount}."

	$ increment!
		-amount! _increment

	$ decrement!
		-amount! _decrement

	$ count
		-amount

`data` is a method of the class `Any-Class` that defines a constructor. (`Any-Class` is the class of classes of anything. More on that later.)
In this case our class will have one *member*.
It is accessed through the two methods (generated by the `data` method), `-amount` and `-amount!`.
We used the `-` to mark this method as private. It can still be publicly accessed though, but what's the fun in that?

`-amount` takes no arguments and simply returns the value of the member.

`-amount!` takes one argument, a Fun which takes the old value and returns the new value. `-amount!` itself returns nothing.

We define instance methods using a single `$`. (Clearly, this is intended to be the most common type of definition.)

What if we want a Counter that 'bottoms out'? We can extend our class.

	\ Positive-Counter.smith

	eg
		blah

	super Counter

	$new decrement!
		try-decrement.unless!
			Error.throw "Could not decrement"

	$ try-decrement!
		Control.returning -amount.positive? \ Calls the Fun on `amount.positive?`, then returns it.
			it.if!
				-amount _decrement

`super` acts like a `use` that also makes this class a sub-class of Counter.
We could have used `trait` instead of `super`. In Smith, a class can be either used as a super-class or a trait, and there is not much difference other than that super-classes use the prototype chain directly for inheritence, while traits need to copy methods into the prototype (using slightly more memory).

`$new` is like `$` but can *override* an already-existing method.

Meta-Classes
---

Every time you create a class, it gets a meta-class. So `Counter.class` will be `Counter-Class` and `Positive-Counter.class` will be `Positive-Counter-Class`.

Just like `Positve-Counter.super-class` is `Counter`, `Positive-Counter-Class.super-class` will be `Counter-Class`. That is, `Counter-Class` is the class of all classes of counters.

All of these methods, `$$`, `data`, `$`, `$new`, are methods of the class `Any-Class`.
`Any-Class` is `Any.class`; the class of classes of anything. It is the root meta-class.
(`Any-Class.class` is `Any`; that is, all classes are values.)

We can define our own class-methods.

	\ Counter.smith
	class.do
		$ new-inc-and-dec new-inc:Fun new-dec:Fun
			\ You can escape the special '$' syntax using 'me.'
			me.$new 'increment new-inc
			me.$new 'decrement new-dec

It is called as a regular method on the class.

	\ Positive-Counter.smith
	new-inc-and-dec
		\ new increment code
	|
		\ new decrement code


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

Smith has a special syntax for single-word strings: `'single-word`. No end-quote needed.

To interpolate a value, simply wrap it in `{}`.
To use literal '{' or escape sequences use `\` before a character.

	Console.log! "1.+ 1 is {1.+ 1}. Curly braces like \{ and }. Tabs \t, new-lines \n, back-slashes \\."

You can also indent a whole block of text. You can still interpolate inside.

	"
		When in the Course of human events,
		it becomes necessary for one people to dissolve the political bands
		which have connected them with another,
		and to assume among the powers of the earth,
		the separate and equal station to which
		the Laws of Nature and of Nature's God entitle them,
		a decent respect to the opinions of mankind requires
		that they should declare the causes which impel them to the separation.
		{1.+ 1}.

Optional and Splat Arguments
---

Sometimes we want to call a method with only a few arguments. For example:

	$$ greet greeting~:Str name:Str
		val greeting
			greeting~.or
				"Hello"
		Console.log! "{greeting}, {name}!"

`~` at the end of a name indicates that it is optional. In this case, any provided value must be a `Str`. The local `greeting~` then becomes an `Opt`. The `or` method is used to provide a default value.

Use `...` if a method receives many arguments.

	$$ greet-all ...names
		names.each greet_

	greet-all 'Matz" 'Moore 'Andy

	val names
		Bag 'Ash 'Misty 'Brock

	greet-all ...names


Standard classes of import
---
Some day documentation for these classes will exist, and it'll be really useful!
Until then you'll just have to slog through the standard-library source code for these classes.

* ! (and !=)
* Any-Class
* Bool
* Ref
* Str
* Meta
* Iterable
* Bag
* List
* Array


JavaScript compatibility
---
In Smith, `.` always means a method call.
To access a property, use `@`, as in `array@length` (or just use `array.size`).

To pass through JavaScript directly, use a \`-indented block:

	`
		I'm JavaScript.

Or just pass through an expression:

	`1 + 1`.twice \ Parentheses added

You can also use the module `Global` to access JavaScript global variables, and `New` to instantiate JavaScript 'classes'.

Known Bugs
---
Segfaults randomly! **D:**


License
---
DO WHATEVER THE FUCK YOU WANT, PUBLIC LICENSE
TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION

0. You just DO WHATEVER THE FUCK YOU WANT.
