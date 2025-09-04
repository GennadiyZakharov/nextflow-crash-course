Basics of Groovy syntax for Nextflow
====================================
for the main scripting language, **Nextflow** uses Groovy — 
a dynamically typed scripting language,
running on top of JVM.
Groovy uses Java-style comments, operators and basic syntax.

This document covers the basics of Groovy syntax, 
required to read and understand Nextflow scripts.

Detailed documentation for Groovy can be found here:
https://groovy-lang.org/documentation.html

Brief and useful section: https://groovy-lang.org/semantics.html

The Nextflow specific topics are covered in the 
[Developing Nextflow pipelines](nextflow-development.md) section.

## Main differences to Java

You don't need semicolons to end statements.

Methods and function calls can omit brackets when it doesn't cause ambiguity:

```groovy
println 'Hello World'
def maximum = Math.max 5, 10 // same as Math.max(5, 10) 
```

Return keyword also can be omitted:
```groovy
int add(int a, int b) {
    a+b // same as return a+b
}
```

Groovy allows using keywords in identifiers using quotas,
(and in some contextual keywords even without it),
but it is better not to do it.

Identifiers (variables and function names) can start with `$` sign.
Also better not to use it to avoid confusion,
because it is used in scripts for variable interpolation.

## Variables

### Definition
Define variable with keywords `def`, or provide type.

```groovy
def name = "Alice"       // dynamic typing
int age = 30             // static typing (optional)
def myBooleanVariable = true // boolean
```

**Note** There is `var` keyword for defining variables, but can't defile complex data structures.
It's easier to use `def` always.


### Strings
Groovy supports:
* 'single quotes'
* "double quotes"
* """triple double quotes""" for multi-line

```groovy
def name = "Alice"
```

The `\` character defines special symbols, same as in Python,
and need to be escaped.

Strings in double quotas and triple double quotas are "GString" 
supporting interpolation (like f-strings in Python)

```groovy
def name = 'Guillaume' // a plain string
def greeting = "Hello ${name}"
assert greeting.toString() == 'Hello Guillaume'
```

To make the end of the variable explicit, use curvy brackets:

```groovy
def verb = 'count'
print "3d form of $verb is ${verb}s"
```

Brackets can interpolate expressions (same as Python f-strings).

```groovy
def sum = "The sum of 2 and 3 equals ${2 + 3}"
```

Slashy strings use / as the opening and closing delimiter.
In fact, just another way to define a GString
but with different escaping rules.
Are particularly useful for defining regular expressions and patterns, 
as there is no need to escape backslashes.

```groovy
def fooPattern = /.*foo.*/
assert fooPattern == '.*foo.*'
```

## Complex data types

### Lists

We can directly define lists with the `def` keywork

```groovy
def numbers = [1, 2, 3]
def heterogeneous = [1, "a", true]
println numbers.size() // get the length of the list
```

Indexing works the same way as in Python

```groovy
def letters = ['a', 'b', 'c', 'd']

assert letters[1] == 'b'     
assert letters[-1] == 'd'    
```

Can assign elements, lists of elements, sublists

```groovy
letters[2] = 'C'             
assert letters[2] == 'C'

letters << 'e'   // Appending an element to the list            
assert letters[ 4] == 'e'
assert letters[-1] == 'e'

assert letters[1, 3] == ['b', 'd']        // comparing lists and parts of lists     
assert letters[2..4] == ['C', 'd', 'e']  
```

### Arrays
We can make homogenous arrays by defining type,
or use `def` + `as` for the same effect.

```groovy
String[] arrStr = ['Ananas', 'Banana', 'Kiwi']
def numArr = [1, 2, 3] as int[] 
```

For Nextflow there is no difference in using arrays or lists.
However, when working with the big amounts of data, 
arrays are more efficient.


### Maps (dictionaries)

Groovy creates maps using square brackets and `:` for delimiter.
Here we use `int` keys:
```groovy
def numbers = [1: 'one', 2: 'two']
assert numbers[1] == 'one'
```

**Blame minute:** By default, in Groovy strings in map keys are not quoted**.
```groovy
def ages = [Alice: 25, Bob: 30]
```
It's good to declare dictionaries in the code, but very confusing:

```groovy
def key = 'name'
def person = [key: 'Guillaume']      

assert !person.containsKey('name') // the 'name' not in dictionary keys   
assert person.containsKey('key')  // instead we created the string key 'key'
```

To use a variable value as the key, 
you must surround the variable or expression with parentheses:

```groovy
def key = 'name'
person = [(key): 'Guillaume']
```

Can access string keys by point notation.

```groovy
def colors = [red: '#FF0000', green: '#00FF00', blue: '#0000FF', 'light blue':'#8888FF']   

assert colors['red'] == '#FF0000'    
assert colors.green  == '#00FF00'
assert colors.'light blue' == '#8888FF' // using quotas to access string key in point notation. 
```

**Blame minute:** !!!Accessing nonexistent elements is not an exception.
Instead, it returns `null`:
```groovy
def emptyMap = [:]
assert emptyMap.anyKey == null
```


### Tuples

Tuples should be declared with def keyword:
```groovy
person = tuple('Alice', 42, false)

def (a, b, c) = [10, 20, 'foo'] // we can use tuples to pack/unpack array elements
def (int i, String j) = [10, 'foo'] // typed tuple
```

Tuples can be accesses by indexes:
```groovy
name = person[0]
age = person[1]
is_male = person[2]

(name, age, is_male) = person
```

## Operators and control structures

In geenral Groovy uses C/Java operators, brackets for blocks and functions.

### Mathematics and logic operators
Mostly the same as in Python, but with more precise variable type control,
determined by the size of the operation.

The standard division `/` returns **float**.
There is no int division operator, like Python `//`.
We can use `intdiv()` method instead

```groovy
assert  3  / 2 == 1.5
assert 10  % 3 == 1
assert  3.intdiv(2) == 1
```

The `===` operator checks object identity (same as `is` in Python)

```groovy
def cat = new Creature(type: 'cat')
def copyCat = cat
def lion = new Creature(type: 'cat')

assert cat == lion      // Groovy shorthand operator
assert cat === copyCat  // operator shorthand
assert cat !== lion     // negated operator shorthand
```

### Ternary operator

Returns value depending on condition

```groovy
result = (string!=null && string.length()>0) ? 'Non-empty' : 'Empty'
```

The "Elvis operator" is a shortening of the ternary operator.
It is useful to check for null or empty value.

```groovy
displayName = user.name ?: 'Anonymous' 
```

Even shorted form is an Elvis assignment

```groovy
atomicNumber ?= 2  // Assign 'atomicNumber' to 2 if before it was null or zero
```

### Safe navigation operator

Avoid a NullPointerException when accessing null-object field.
Returns `null` instead

```groovy
def person = null    
def name = person?.name                      
assert name == null  
```

### Regular expression operators

The pattern operator (`~`) creates a regexp object

Use `=~` to check whether a given pattern occurs anywhere in a string:

```groovy
assert 'hello' =~ /hello/
assert 'hello world' =~ /hello/
```

The `=~` returns match object - we can use it:

```groovy
def programVersion = '2.7.3-beta'
def m = programVersion =~ /(\d+)\.(\d+)\.(\d+)-?(.+)/

assert m[0] == ['2.7.3-beta', '2', '7', '3', 'beta']
assert m[0][1] == '2'
```

Use `==~` to check whether a string matches a given regular expression pattern exactly.

```groovy
assert 'hello' ==~ /hello/
assert !('hello world' ==~ /hello/)
```


### Coercion operator (`as`)

Converts objects from one type to another without them being compatible for assignment.
Automatically calls `asType()` conversion methods. 

```groovy
String input = '42'
//Integer num = (Integer) input // Will return an error - can't convert int to string
Integer num = input as Integer // This works
```


### Control flow operators

Mostly the same, as in C/Java.
```groovy
C/Java style `if` operator:
if (age > 18) {
    println "Adult"
} else {
    println "Minor"
}

// C/Java-style for loops
String message = ''
for (int i = 0; i < 5; i++) {
    message += 'Hi '
}
assert message == 'Hi Hi Hi Hi Hi '

// for-each style
def x = 0
for ( i in 0..9 ) { // iterate over a range
    x += i
}
assert x == 45

// while loop
var i = 0
while (i < 3) {
    println i
    i++
}
```

## Functions

### "Regular" functions

Defined in C/JAva-way - name ang arguments:
```groovy
def greet(name) {
    return "Hello, $name"
}
```

## Closures
A closure is a function that can be used like a regular value. 

```groovy
def square = { x -> x * x }
println(square(5)) // returns 25
// The brackets `()` are used to call closure and return the result.
```

The main use case for a closure is as an argument to a higher-order function:

```groovy
[ 1, 2, 3, 4 ].each({ v -> v * v }) // returns [ 1, 4, 9, 16 ]

// same way with omitting brackets:
[ 1, 2, 3, 4 ].collect { v -> v * v }

// print elements of a dictionary
[ "Yue" : "Wu", "Mark" : "Williams", "Sudha" : "Kumari" ].each { key, value ->
    println "$key = $value"
}
```

Closures can have typed parameters:

```groovy
def closureWithTwoArgsAndExplicitTypes = { int a, int b -> a+b }
assert closureWithTwoArgsAndExplicitTypes(1,2) == 3
```

When a closure does not explicitly define a parameter list (using ->), 
a closure always defines an implicit parameter, named `it`. This means that this code:

```groovy
def greeting = { "Hello, $it!" }
assert greeting('Patrick') == 'Hello, Patrick!'
```

Closures can access variables outside their scope:

```groovy
def counts = ["China": 1, "India": 2, "USA": 3]

def result = 0
counts.keySet().each { v ->
    result += counts[v] // v is a closure argument, but we have access to externally defined 'counts' variable
}

println result
```


### Closures in GStrings

Simple GString evaluated when defined
```groovy
def x = 1
def gs = "x = ${x}"
assert gs == 'x = 1'

x = 2
assert gs == 'x = 2' // This will fails, because expressions are populated when created
```

Closures in GStrings evaluated when called.

```groovy
def x = 1
def gs = "x = ${-> x}" // here the clusure access external variable 'x'
assert gs == 'x = 1'

x = 2
assert gs == 'x = 2' // this works, closure gets the new value of x
```

