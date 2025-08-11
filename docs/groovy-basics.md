Basics of Groovy syntax for Nextflow
====================================
**Nextflow** uses Groovy for the main scripting language  
and adds to it some NextFlow-specific constructions. 

This document covers the basics of Groovy syntax, 
required to read and understand Nextflow scripts.

Detailed documentation for Groovy can be found here:
https://groovy-lang.org/documentation.html

Brief and useful section: https://groovy-lang.org/semantics.html
 
# Introduction

**Groovy** dynamically-types scripting language,
running on top of JVM. 
Can directly run Java classes.

Java-style comments, operators and basic syntax, but no semicolons.

**Note: non-usual syntax**:

Methods and function calls can omit parenthesis

```groovy
println 'Hello World'
def maximum = Math.max 5, 10
```

Return keyword also can be omitted:

```groovy
int add(int a, int b) {
    a+b
}
```

## Keywords and identifiers
Groovy allows using keywords in identifiers using quotas,
(and in some contextual keywords even without it),
but it is better not to do it.

Identifiers (variables and function names) can start with `$` sign.
Also better not to use it to avoid confusion.

## Quoted identifiers

Quoted identifiers appear after the dot of a dotted expression. 
For instance, the name part of the `person.name` expression can be quoted with 
`person."name"` or `person.'name'`.
It is useful when accessing elements of maps (dictionaries) 
containing spaces and other illegal characters.

# Variables

## Definition
Define variable with keywords `def`, `var`, or provide type.

```groovy
def name = "Alice"       // dynamic typing
int age = 30             // static typing (optional)
var index = "CB1 9AX"    // dynamic typing with var keyword
def myBooleanVariable = true // boolean
```

**Note** The `var` keyword can't defile complex data structures
It's easier to use `def` always.


## Strings
Groovy supports:
* 'single quotes'
* "double quotes"
* """triple double quotes""" for multi-line

```groovy
var name = "Alice"
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

To make the end of the variable explicit, we use brackets:

```groovy
def verb = 'count'
print "3d form of $verb is ${verb}s"
```

Brackets can interpolate expressions (same as Python f-strings).

```groovy
def sum = "The sum of 2 and 3 equals ${2 + 3}"
```

### Slashy strings

Slashy strings use / as the opening and closing delimiter.
In fact, just another way to define a GString
but with different escaping rules.
Are particularly useful for defining regular expressions and patterns, 
as there is no need to escape backslashes.

```groovy
def fooPattern = /.*foo.*/
assert fooPattern == '.*foo.*'
```

# Complex data types

## Lists

We can directly define lists with the `def` keywork

```groovy
def numbers = [1, 2, 3]
def heterogeneous = [1, "a", true]
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

## Arrays
We can make homogenous arrays by defining type.
We can use `def` + `as` for the same effect

```groovy
String[] arrStr = ['Ananas', 'Banana', 'Kiwi']
def numArr = [1, 2, 3] as int[] 
```

To make an uninitialized array, we can define the size 
or leave it blank.
We can't use the `as` keyword here.

```groovy
def matrix3 = new Integer[3][3]
Integer[][] matrix2 
```

For cakward compatibility with Java, groovy can use
Kava style array init with `{}`

```groovy
def primes = new int[] {2, 3, 5, 7, 11}
```

## Maps (dictionaries)

Groovy creates maps using square brackets and `:` for delimiter.
here we use `int` keys
```groovy
def numbers = [1: 'one', 2: 'two']
assert numbers[1] == 'one'
```

**!!! Important: By default, strings in map keys are not quoted**.
```groovy
def ages = [Alice: 25, Bob: 30]
```

Good to declare dictionaries in the code, but very confusing:

```groovy
def key = 'name'
def person = [key: 'Guillaume']      

assert !person.containsKey('name') // the 'name' not in dictionary keys   
assert person.containsKey('key')  // instead we ckeated the srting 'key' key
```

**To use a variable value as the key, 
you must surround the variable or expression with parentheses:**

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

**!!!BAD Accessing nonexistent elements is not an exception.
Instead, it returns null**
```groovy
def emptyMap = [:]
assert emptyMap.anyKey == null
```


## Tuples and multiple assignment

```groovy
// Tuples should be declared with def keyword
def (a, b, c) = [10, 20, 'foo']
def (int i, String j) = [10, 'foo'] // typed tuple
```


# Operators and control structures

C-like operators, brackets for blocks and functions

## Mathematics and logic operators
Mostly the same as in Python, but with more precise variable size control,
determined by the size of the operation.

**Note:**
The standard division `/` returns **float**
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

## Ternary operator

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
atomicNumber ?= 2  // Assing to 2 if null or zero
```

## Safe navigation operator

Avoid a NullPointerException when accessing null-object field.
Returns null instead

```groovy
def person = null    
def name = person?.name                      
assert name == null  
```

## Regular expression operators

The pattern operator (`~`) created regexp object

Use =~ to check whether a given pattern occurs anywhere in a string:

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
assert m[0][2] == '7'
assert m[0][3] == '3'
assert m[0][4] == 'beta'
```

Use ==~ to check whether a string matches a given regular expression pattern exactly.

```groovy
assert 'hello' ==~ /hello/
assert !('hello world' ==~ /hello/)
```


## Coercion operator (`as`)

Converts objects from one type to another without them being compatible for assignment.
Automatically calls `asType()` conversion methods. 

```groovy
String input = '42'
//Integer num = (Integer) input // Will retunr an error - can't convert int to string
Integer num = input as Integer // This works
```



## Control flow operators

```groovy
if (age > 18) {
    println "Adult"
} else {
    println "Minor"
}

// C-style for loops
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

# Functions

## "Regular" fucntions

Defined in C-way - name ang arguments
```groovy
def greet(name) {
    return "Hello, $name"
}
```

# Closures
A closure is a function that can be used like a regular value. Typically, closures are passed as arguments to higher-order functions to express computations in a declarative manner.


```groovy
def square = { x -> x * x }
println(square(5))
```

The main use case for a closure is as an argument to a higher-order function:

```groovy
[ 1, 2, 3, 4 ].collect({ v -> v * v })

// same way with omitting brackets:
[ 1, 2, 3, 4 ].collect { v -> v * v }

// print elements of a dictionary
[ "Yue" : "Wu", "Mark" : "Williams", "Sudha" : "Kumari" ].each { key, value ->
    println "$key = $value"
}
```

The brackets `()` are used to call closure ane return result.
In fact, this is a syntaxic sugar for the `.call()` method 
of the closure object.

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


Closures can access variables outside of their scope:

```groovy
def counts = ["China": 1, "India": 2, "USA": 3]

def result = 0
counts.keySet().each { v ->
    result += counts[v]
}

println result
```


## Closures in GStrings

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
def gs = "x = ${-> x}"
assert gs == 'x = 1'

x = 2
assert gs == 'x = 2' // this works, closure gets the new value of x
```

## Currying

We can apply several arguments to a closure and receive a new closure.

```groovy
def nCopies = { int n, String str -> str*n }    
def twice = nCopies.curry(2)                    
assert twice('bla') == 'blabla'                 
```



