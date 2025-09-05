Developing Nextflow pipelines
=============================

## Introduction

Nextflow language is a combination of Groovy scripting and Nextflow-specific 
language constructs: workflows, processes, channels, and modules.
A short summary regarding scripts syntax is available in the 
[Nextflow scripting](https://www.nextflow.io/docs/latest/script.html) section.
The same information is also available in the 
[Groovy basics](groovy-basics.md) section.

## Processes

In Nextflow, a process is a specialized function for executing scripts in a scalable and portable manner.
Detailed documentation is in the 
[Nextflow processes](https://www.nextflow.io/docs/latest/process.html#processes) section.
In fact, a process is a wrapper for a shell script.

```nextflow
process hello {
    script:
        """
        echo 'Hello world!' > hello.txt
        """
}
```

The `script` section defines, as a string expression, the script that is executed by the process. 
A process must define a script section. All other sections are optional. 

**A blame minute**: The definition of Nextflow-specific constructions doesn't follow Groovy syntax. 
Instead, they are defined using Python-style keywords with `:` symbol: `input:`, `output:`, `script:`, etc.
However, the tabulation doesn't affect the script syntax.
Each section ends when the next section starts.
I use Python-style indentation because I like it and believe 
that it makes code more readable.

Nextflow processes have access to all Groovy variables and methods,
defined in the process scope.
In addition, processes consume ane return data via channels.
Usually, channels pass to processes variables and file paths.

The quoted text in the script section is a groovy GString, 
which means that you can use string interpolation in it.
Here the `str` variable is interpolated using values passed from the input channel.

```nextflow
process say {
    input:
        val str
    script:
        """
        echo "We say $str" > out.txt
        """
    output:
        path 'out.txt'
}
```

To execute a process, you must invoke it in a workflow.
Channels are passed to the process as arguments.
```nextflow
workflow {
    greetings = channel.of('Hello', 'Hola', 'Bonjour')
    say(greetings)
}
```

Nextflow can interpolate and execute scripts in any language :
```nextflow
process perl_task {
    script:
        """
        #!/usr/bin/perl
        print 'Hi there!' . '\n';
        """
}
```

**Warning!** 
Since Nextflow uses the same Bash syntax for variable substitutions in strings,
you must manage them carefully depending on whether you want to evaluate a Nextflow variable or a Bash variable.
You can define your script with double-quotes and escape the system environment variables 
by prefixing them with a back-slash `\` character:
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

You can use Groovy inside any definition block:
For example, if-else statements can be used to produce different scripts
depending on the variable values.

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

The exec section executes the given code without launching a job.
This is a native process that is very similar to a function. 
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

### Process input

The input section defines input channels of a process, similar to function arguments.
More details are available in the 
[Nextflow processes input](https://www.nextflow.io/docs/latest/process.html#inputs) section.

The input section follows the syntax shown below:
```nextflow
input:
    <input qualifier> <input name>
```

The input qualifier defines the type of data to be received.
From the syntax point of view, the input qualifier is a function that consumes the input name as a parameter.
In Groovy we can omit brackets when calling a function.

When a process is invoked in a workflow, it must be provided a channel for each channel in the process input section, 
similar to calling a function with specific arguments. 

The most popular input qualifiers are:

#### Value
`val x` : Access the input value by name in the process script. `echo "process job $x"`
Created by a channel form a list: `def num = channel.of(1,2,3)`
Can pass numbers or strings.

Nextflow has service functions that can parse table files (csv, tsv)
and convert lines from it into a channel.

#### Path
`path query_file`: Handle the input value as a path, 
staging the file properly in the execution context. `blastp -query ${query_file} -db nr`

Created by assigning files by mask: `def proteins = channel.fromPath('/some/path/*.fa')`
Can assign a fixed name for a file: `path query_file, name: 'query.fa'`
We can implicitly make a channel from a single path: `workflow { my_process('/some/data/file.txt') }`

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

#### Tuple
Tuple groups multiple values into a single input definition. 
It can be useful when a channel emits several values that need to be handled separately. 
Each element in the tuple is associated with a corresponding element in the tuple definition.
As above, from the syntax point of view `tuple()` is a function that consumes other qualifiers as parameters,
but we omit the brackets.

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
```

To pass a channel to a process, you can use the `|` notation.
```nextflow
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
Each time a file of sequences is emitted from the sequences channel, the process executes three tasks, 
each running a T-coffee alignment with a different value for the mode parameter. 

### Process output
In general, follows the same syntax as output.
All quantifiers (val, path, env, ...) are available for outputs.
You can find the details in the 
[Nextflow processes output](https://www.nextflow.io/docs/latest/process.html#outputs) section.


## Channels

In Nextflow,
dataflow channels (or simply channels) are asynchronous sequences of values.
Channels transfer data between processes.
Detailed description is here: https://www.nextflow.io/docs/latest/channel.html#channels

There are two kinds of channels:
* A queue channel is a channel that emits an asynchronous sequence of values.
* A value channel is a channel that is bound to an asynchronous value.

### Queue channels

A queue channel can be created by channel factories (e.g., `channel.of` and `channel.fromPath`), 
operators (e.g., map and filter), and processes.
For example, `channel.of()` - created a channel with a sequence of values:

The data in a channel cannot be accessed directly, but only through an operator or process. For example:

```nextflow
channel.of(1, 2, 3).view { v -> "channel emits ${v}" }
```

A value channel can be created with the `channel.value` factory, 
certain operators (e.g., collect and reduce), and processes (under certain conditions).

When two or more channels are declared as process inputs, 
the process waits until there is a complete input configuration, i.e. until it receives a value from each input channel. 
When this condition is satisfied, the process consumes a value from each channel and launches a new task, 
repeating this logic until one or more channels are empty.

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

The process echo is executed two times because the `x` channel emits only two values, 
therefore the `c` element is discarded.

### Value channels
**Value channel** infinitely creates one value

```nextflow
workflow {
  x = channel.value(1).  // infinitely produces value '1'
  y = channel.of('a', 'b', 'c')
  echo(x, y) // will be executed 3 times
}
```

### Process outputs channels

When an output path channel has file mask with wildcard characters, it is interpreted as a glob path matcher.
The channel captures all the files that match the pattern, and emit the list of files as a single value.
The `flatten` operator can be used to transform the list of files into a channel that emits each file individually.

```nextflow
process split_letters {
    script:
        """
        printf 'Hola' | split -b 1 - chunk_
        """
    output:
        path 'chunk_*'
}

workflow {
    split_letters // using | to chain processes and channels
        | flatten
        | view { chunk -> "File: ${chunk.name} => ${chunk.text}" }
}
```

### Channel Operators

Channel operators, or operators for short, are functions that consume and produce channels.
Operators are particularly useful for implementing glue logic between processes.

Commonly used operators include:
* `flatten`: flatten a list from channel and emits each list element individually.
* `collect`: - opposite to `flatten`. Collects the values from a channel into a list and emits is as a single value
* `filter`: select the values in a channel that satisfy a condition
* `flatMap`: transform each value from a channel into a list and emit each list element separately
* `groupTuple`: group the values from a channel based on a grouping key
* `join`: join the values from two channels based on a matching key
* `map`: transform each value from a channel with a mapping function
* `mix`: emit the values from multiple channels
* `view`: print each value in a channel to standard output. Can accept closure to customize output


## Workflows

In Nextflow, a workflow is a function that composes processes 
and dataflow logic (i.e. channels and operators).

Details regarding workflows are in the 
[Nextflow workflows](https://www.nextflow.io/docs/latest/workflow.html) section.

A script can define up to one entry workflow, 
which does not have a name and serves as the entrypoint of the script:

```nextflow
workflow {
    channel.of('Bonjour', 'Ciao', 'Hello', 'Hola') // the point notation is the third way to chain data processing
    .map { v -> "$v world!" }
    .view()
}
```

A script can declare parameters using the params block (JSON-like syntax):

```nextflow
params {
    input_fastq: Path
    refrence_genome: str = "GRCh38"
    save_intermeds: Boolean = false // Whether to save intermediate files.
}
```

The default value can be overridden by the command line, params file, or config file.
Parameters from multiple sources are resolved in the order described in 
[Pipeline parameters](https://www.nextflow.io/docs/latest/cli.html#cli-params).
As a best practice, parameters should only be used directly in the entry workflow
and passed to workflows and processes as explicit inputs.

A named workflow is a workflow that can be called by other workflows:
```nextflow
workflow my_workflow {
    hello()
    bye( hello.out.collect() )
}

workflow {
    my_workflow()
}
```

When calling the workflow, the output can be accessed using the out property, i.e. `my_workflow.out`


### Takes and emits

The `take:` section declares the inputs of a named workflow.
The `emit:` section declares the outputs of a named workflow.
If an output is assigned to a name, the name can be used to reference the output from the calling workflow.

```nextflow
workflow hello_bye {
    take:
        data
    main:
        hello_out = hello(data)
        bye(hello_out)
    emit:
        bye = bye.out
}
```

Named outputs can be accessed as properties of the return value:

```nextflow
workflow {
    data = channel.fromPath('/some/path/*.txt')
    flow_out = hello_bye(data)
    bye_out = flow_out.bye
}
```

### Calling processes and workflows

Processes and workflows are called like functions, passing their inputs as arguments:

Processes and workflows have a few extra rules for how they can be called:
* Processes and workflows can only be called by workflows
* A given process or workflow can only be called once in a given workflow. 
  To use a process or workflow multiple times in the same workflow, use `Module` aliases.

### Workflow outputs

A workflow or a process can have `publishDir` directive that declares
that we want to publish output files from this workflow or process.
All data files declared in the `output` section of the workflow are automatically published
the the directory specified by the `publishDir` directive.


```nextflow
process fetch {
    publishDir 'results/fetch'
    // ...
    output:
        path 'sample.txt'
    // ...
}
```

### New style publishing
There is a preview version of Nextflow syntax 
that supports publishing of data files in a more flexible way, using `output {}` block.
We don't consider it for now since its syntax and capabilities are not finalized.
For details see [here](https://www.nextflow.io/docs/latest/workflow.html#workflow-outputs).










