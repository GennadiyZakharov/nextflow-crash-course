Nextflow crash course
=====================

This is a short tutorial for the **Nextflow** pipeline engine, 
It provides minimum basics to start working with Nextflow,
both running existing pipelines and creating your own.

## Introduction

Nextflow (https://www.nextflow.io/)
is the workflow orchestration language and engine developed by Seqera company (https://seqera.io/).
Technically, it is a domain-specific language (DLS) built on top of the Groovy language (https://groovy-lang.org/).

The most part of Nextflow pipelines in bioinformatics
follow the template defined by NF-Core community (https://nf-co.re/).

The biggest advantage of Nextflow is the ability to
launch and cache data-driven processes.
For example, when you need to split your data in fixed-sized chunks,
perform some operations on each chunk and merge the results.

When you don't know the number of chunks in advance,
file-driven workflow engines (like Snakemake)
seriously struggle.

## How Nextflow works

The Nextflow is a Groovy script with additional DSL blocks
Nextflow reads and executes it as a regular script.

To work with the data, Nextflow defines two key concepts:
**processes** and **channels**.

Nextflow **channels** are the basic unit of data flow.
They are queues that pass data between processes.
For example, you can take all files by a pattern `.cram` from a directory
and put them into a channel.
Channels can handle multiple types of data:
numbers, booleans, file paths, etc. 

Nextflow **processes** are the basic unit of execution.
Each process consumes data from a channel and produces data to another channel.
For example, you can define a process that takes a `.cram` file from the input channel,
generates a `.crai` index for it,
and passes it to the output channel.

Each time the process receives from input channels enough data to start execution,
Nextflow creates a **task**.

**Task** is an instance of a process execution.
For example, in the example above, each `cram` file from the input channel will
launch a separate task.

Nextflow runs tasks in parallel depending on the available resources.
The execution of tasks is asynchronous -- therefore the resulting `.crai`
indexes may be generated in different order than the input `.cram` files.

### Task orchestration

The task is launched only when it has the full set of input data.
For example, you can define another process that has two input channels for `.cram` and `crai` files.
A task for this process will be launched only when both `.cram` and `crai` files 
are available in the input channels.


### Filesystem organization

From the filesystem perspective, each task is a separate directory
inside the Nextflow work directory.
This directory contains symlinks to all input data files and scripts required to run the task.

When the data via channels is passed to another task,
Nextflow creates a new folder for the task and symlinks all required files into it.
You can have different file names in different processes.
Nextflow will ensure that all symlinks are correctly created.

Each process can "publish" some output data
(in addition to sending it to the output channel or instead of it), 
which means that Nextflow,
copies/symlinks it to the output directory.

### Task caching

Nextflow uses tass input data (input files, parameters, environment and config variables
to create a task hash, and stores all this information into a database folder.

If you modify and rerun your pipeline with the `-resume` option, 
Nextflow checks if the task is already cached and skips the execution. 
Therefore, only new and modified tasks are executed.

**A blame minute:** Nextflow uses task hashes to name task directories,
therefore, it's very hard to find all the tasks for a particular process.
After several iterations of parameter modification and reruns, 
you can end up with a huge number of obsolete tasks in your working directory,
and it's near impossible to clean it up.

## How to use Nextflow pipelines

To learn how to run Nextflow pipelines,
see the [Nextflow usage howto](docs/nextflow-usage.md).

## How to develop Nextflow pipelines

To learn how to run Nextflow pipelines,
review the [Groovy syntax basics](docs/groovy-basics.md),
and see the [Nextflow pipelines development howto](docs/nextflow-development.md).


