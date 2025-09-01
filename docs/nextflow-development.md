Developing Nextflow pipelines
=============================

Nextflow is a workflow language that runs on the Java virtual machine (JVM). Nextflow’s syntax is very similar to Groovy, a scripting language for the JVM. However, Nextflow is specialized for writing computational pipelines in a declarative manner.

Documentation link: https://www.nextflow.io/docs/latest/script.html 


## Workflows

Nextflow scripts are composed of workflows, processes, and functions (collectively known as definitions), and can include definitions from other scripts.

```nextflow
workflow {
    println 'Hello!'
}
```

Workflows and processes can call fucntions

## Working with files

To access and work with files, use the file() method:

```nextflow
myFile = file('some/path/to/my_file.file')
```

The `file()` method returns a `Path`

The simplest way to list a directory is to use list() or listFiles(), which return a collection of first-level elements (files and directories) of a directory

```nextflow
for( def file : file('any/path').list() ) {
    println file
}
```

## Processes

In Nextflow, a process is a specialized function for executing scripts in a scalable and portable manner.

```nextflow
process hello {
    output:
    path 'hello.txt'

    script:
    """
    echo 'Hello world!' > hello.txt
    """
}
```
The script section defines, as a string expression, the script that is executed by the process. The script section can be a simple string or a multi-line string.
The script string is executed as a Bash script in the host environment.
A process must define a script section. All other sections are optional. 

**Warning:**
Since Nextflow uses the same Bash syntax for variable substitutions in strings, 
you must manage them carefully depending on whether you want to evaluate a Nextflow variable or a Bash variable.
you can define your script with double-quotes and escape the system environment variables by prefixing them with a back-slash `\` character:

```nextflow
process blast {
  // $MAX is a Nextflow variable
  // $DB is a Bash variable that must exist in the execution environment
  """
  blastp -db \$DB -query query.fa -outfmt 6 > blast_result
  cat blast_result | head -n $MAX > sequences
  """
}
```

Nextflow can interpolate and execure script in any languadge:

```nextflow
process perl_task {
  script:
    """
    #!/usr/bin/perl

    print 'Hi there!' . '\n';
    """
}
```

If-else statements based on task inputs can be used to produce a different script.

```nextflow
mode = 'tcoffee'

process align {
    input:
    path sequences

    script:
    if( mode == 'tcoffee' )
        """
        t_coffee -in $sequences > out_file
        """

    else if( mode == 'mafft' )
        """
        mafft --anysymbol --parttree --quiet $sequences > out_file
        """

    else
        error "Invalid alignment mode: ${mode}"
}
```

Process scripts can be externalized to template files

```nextflow
process hello {
    input: val STR

    script:
    template 'hello.sh' // Nextflow looks for the template script 
    // in the templates directory
    // and process it
}
```

The exec section executes the given code without launching a job.
A native process is very similar to a function. 
However, it provides additional capabilities such as parallelism, caching, and progress logging.

```nextflow
process hello {
    input:
    val name

    exec:
    println "Hello Mr. $name"
}

workflow {
    channel.of('a', 'b', 'c') | hello
}
```

You can define a command stub, which replaces the actual process command 
when the `-stub-run` or `-stub` command-line option is enabled:

```nextflow
process salmon_index {
    input:
    path transcriptome

    output:
    path 'index'

    script:
    """
    salmon index --threads $task.cpus -t $transcriptome -i index
    """

    stub:
    """
    mkdir index
    touch index/seq.bin
    touch index/info.json
    touch index/refseq.bin
    """
}
```



## Process input

The input section allows you to define the input channels of a process, similar to function arguments. 
The input section follows the syntax shown below:

```nextflow
input:
  <input qualifier> <input name>
```

The input qualifier defines the type of data to be received. 
When a process is invoked in a workflow, it must be provided a channel for each channel in the process input section, similar to calling a function with specific arguments. 

The following input qualifiers are available: 
#### Value
`val x` : Access the input value by name in the process script. `echo "process job $x"`
Created by channel form list: `def num = channel.of(1,2,3)`

#### Path
`path query_file`: Handle the input value as a path, staging the file properly in the execution context. `blastp -query ${query_file} -db nr`

Created by assigning files by mask: `def proteins = channel.fromPath( '/some/path/*.fa' )`
Can assign a fixed name for a file: `path query_file, name: 'query.fa'`
we can implicitely make a channel form a single path: `workflow { my_process('/some/data/file.txt') }`

The `arity` option can be used to enforce the expected number of files, either as a number or a range.
```nextflow
input:
    path('one.txt', arity: '1')         // exactly one file is expected
    path('pair_*.txt', arity: '2')      // exactly two files are expected
    path('many_*.txt', arity: '1..*')   // one or more files are expected
```

You can also use other input values as variables in the file name string:
```nextflow
process grep {
  input:
  val x
  path "${x}.fa"

  script:
  """
  cat ${x}.fa | grep '>'
  """
}
```




#### Env
The env qualifier allows you to define an environment variable in the process execution context based on the input value.

```nextflow
process echo_env {
    input:
    env 'HELLO'

    script:
    // Using single quotas to avoid nextflow variable interpolation
    '''
    echo "$HELLO world!"
    '''
```


#### stdin
forward the input value to the standard input of the process script.
```nextflow
process cat {
  input:
  stdin

  script:
  """
  cat -
  """
}
```

#### tuple
group multiple values into a single input definition. It can be useful when a channel emits tuples of values that need to be handled separately. Each element in the tuple is associated with a corresponding element in the tuple definition.

```nextflow
process cat {
    input:
    // Val and Path are fucntions, but before we omit ()
    // Here we have to use it to avoid ambuguity.
    tuple val(x), path('input.txt')
    script:
    """
    echo "Processing $x"
    cat input.txt > copy
    """
}

workflow {
  channel.of( [1, 'alpha.txt'], [2, 'beta.txt'], [3, 'delta.txt'] ) | cat
}
```

#### Input repeaters (each)

The `each` qualifier allows you to repeat the execution of a process for each item in a collection, each time a new value is received.

```nextflow
process align {
  input:
  path seq
  each mode

  script:
  """
  t_coffee -in $seq -mode $mode > result
  """
}

workflow {
  sequences = channel.fromPath('*.fa')
  methods = ['regular', 'espresso', 'psicoffee']

  align(sequences, methods)
}
```
each time a file of sequences is emitted from the sequences channel, the process executes three tasks, each running a T-coffee alignment with a different value for the mode parameter. This behavior is useful when you need to repeat the same task over a given set of parameters.

## Output
In general, follows the same syntax as output.
All quatifiers (val, path, env, ...) are available for outputs.


## Channels

In Nextflow, channels are the key data structures that facilitate the dataflow dependencies between each step (i.e. process) in a pipeline.
There are two kinds of channels:
* A queue channel is a channel that emits an asynchronous sequence of values.
* A value channel is a channel that is bound to an asynchronous value.

A queue channel can be created by channel factories (e.g., channel.of and channel.fromPath), 
operators (e.g., map and filter), and processes (see Process outputs).
`channel.of(1, 2, 3).view { v -> "queue channel emits ${v}" }`

A value channel can be created with the channel.value factory, certain operators (e.g., collect and reduce), and processes (under certain conditions).

The values in a queue channel cannot be accessed directly – they can only be accessed by passing the channel as input to an operator or process. For example:

When two or more channels are declared as process inputs, the process waits until there is a complete input configuration, i.e. until it receives a value from each input channel. When this condition is satisfied, the process consumes a value from each channel and launches a new task, repeating this logic until one or more channels are empty.


`channel.of()` - created a channel with a sequence of values:

```nextflow
process echo {
  input:
  val x
  val y

  script:
  """
  echo $x and $y
  """
}

workflow {
  x = channel.of(1, 2)
  y = channel.of('a', 'b', 'c')
  echo(x, y)
}
```

The process echo is executed two times because the x channel emits only two values, therefore the c element is discarded.

**Value channel** infinitely creates one value

```nextflow
workflow {
  x = channel.value(1).  // infinitely produces value '1'
  y = channel.of('a', 'b', 'c')
  echo(x, y) // will be executed 3 times
}
```

In general, multiple input channels should be used to process combinations of different inputs, 
using the each qualifier or value channels. 
Having multiple queue channels as inputs is equivalent to using the merge operator, 
which is not recommended as it may lead to non-deterministic process inputs.


### Process outputs

When an output file name contains a * or ? wildcard character, it is interpreted as a glob path matcher. 
This allows you to capture multiple files into a list and emit the list as a single value.

The `flatten` operator can be used to transform the list of files into a channel that emits each file individually.

```nextflow
process split_letters {
    output:
    path 'chunk_*'

    script:
    """
    printf 'Hola' | split -b 1 - chunk_
    """
}

workflow {
    split_letters
        | flatten
        | view { chunk -> "File: ${chunk.name} => ${chunk.text}" }
}
```

The arity option can be used to enforce the expected number of files, either as a number or a range.

```nextflow
output:
    path('one.txt', arity: '1')         // exactly one file is expected
    path('pair_*.txt', arity: '2')      // exactly two files are expected
    path('many_*.txt', arity: '1..*')   // one or more files are expected
```

### Channel Operators

Channel operators, or operators for short, are functions that consume and produce channels. 
Because channels are asynchronous, operators are necessary to manipulate the values in a channel. Operators are particularly useful for implementing glue logic between processes.

Commonly used operators include:
* combine: emit the combinations of two channels
* collect: collect the values from a channel into a list
* filter: select the values in a channel that satisfy a condition
* flatMap: transform each value from a channel into a list and emit each list element separately
* groupTuple: group the values from a channel based on a grouping key
* join: join the values from two channels based on a matching key
* map: transform each value from a channel with a mapping function
* mix: emit the values from multiple channels
* view: print each value in a channel to standard output


## Workflows

In Nextflow, a workflow is a function that is specialized for composing processes and dataflow logic (i.e. channels and operators).

```nextflow
workflow {
    channel.of('Bonjour', 'Ciao', 'Hello', 'Hola')
        .map { v -> "$v world!" }
        .view()
}
```

Parameters can be declared in a Nextflow script with the params block

A script can declare parameters using the params block:

```nextflow
params {
    // Path to input data.
    input: Path

    // Whether to save intermediate files.
    save_intermeds: Boolean = false
}
```






