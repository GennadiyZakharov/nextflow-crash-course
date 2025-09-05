Nextflow usage
==============

## Command-line parameters

In the most simple way, to run a workflow, you only need to specify the name of the workflow script:
```bash
nextflow run example-01/find_matches.nf
```

* The parameters with single dash are Nextflow engine parameters (`-resume`)
* The parameters with double dash are workflow parameters: `--size`
  They override defaults provided in the pipeline code.

```bash
nextflow run example-01/find_matches.nf --size=5000000
```
For complicated workflows, you can use a config file that overrides the default parameters,
defined in the pipeline code:
```bash
nextflow -config my.config
```

You can provide parameters in a separate file (JSON or YAML):

```
params {
  "size": 5000000
}
```

```bash
nextflow -params-file my_params.json
```

Parameters are applied in the following order (from lowest to highest priority):
1. Parameters defined in pipeline scripts (e.g. main.nf)
2. Parameters defined in config files
3. Parameters specified in a params file (-params-file)
4. Parameters specified on the command line (--something value)

## Pulling projects

Nextflow can pull and execute pipelines from git repositories

```bash
nextflow run nextflow-io/hello -r mybranch
```


