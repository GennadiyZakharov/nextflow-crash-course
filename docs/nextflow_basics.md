Basics of Nextflow pipeline engine
==================================

## Introduction

Nextflow is the pipeline language developed by Sequester company.
Technically, it is a DSL built on top of the Groovy language.

Nextflow executes scripts and runs processes defined in it.
The biggest advantage of Nextflow is the ability to 
launch and cache data-driven processes.
For example, when you need to split a file in fixed-sized chunks 
and don't know the number of chunks.
File-driven workflow engines (like Snakemake)
seriously struggle with this kind of tasks.

The most part of Nextflow pipelines in bioinformatics
follow the template defined by NF-core.

## How Nextflow works

The Nextflow pipeline is a groovy script with additional DSL blocks
Nextflow reads and executes it as a regular script.

## Input parameters

The parameters with single dash are Nextflow parameters: `-resume`
The parameters with double dash are workflow parameters
They override defaults provided in the pipeline values

```bash
nextflow run example-01/find_matches.nf --size=5000000
```

Providing a config file overrides defaults:
```bash
nextflow -config my.config
```

You can provide paremeters in a separate file (JSON or YAML):

```json
params {
  "alpha": "default config value"
}
```

Parameters are applied in the following order (from lowest to highest priority):
1. Parameters defined in pipeline scripts (e.g. main.nf)
2. Parameters defined in config files
3. Parameters specified in a params file (-params-file)
4. Parameters specified on the command line (--something value)

### Pulling projects

Nextflow can pull and execute pipelines from git repositories

```bash
nextflow run nextflow-io/hello -r mybranch
```


## Modify and resume

Each task is executed in a separate directory under the Nextflow work directory.
All inputs are linked inside this directory from the input data location or from
previous tasks.

Nextflow tracks task executions in a task cache, a key-value store of previously executed tasks.
If you modify and resume your pipeline, only the processes that are changed will be re-executed. 
The cached results will be used for tasks that don’t change.

You can enable resumability using the `-resume` option.


