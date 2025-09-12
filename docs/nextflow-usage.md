Nextflow usage
==============

## Command-line parameters

In the most simple way, to run a workflow, you only need to specify the name of the workflow script:
```bash
nextflow run examples/find_matches.nf
```

* The parameters with single dash are Nextflow engine parameters (`-resume`)
* The parameters with double dash are workflow parameters: `--size`
  They override defaults provided in the pipeline code.

```bash
nextflow run examples/find_matches.nf --size=5000000
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

## Working on the Sanger institute HPC cluster
Nextflow has build-in support of 'profiles' -- wrappers that adopt scripts to run in different environments.
**Docker**, **Singularity** and **Conda** profiles are suitable for the local execution.
Nextflow processes have a special section to define names of images or conda environments.

Most organizations with HPC environments support custom profiles to run Nextflow pipelines.
To use Nextflow profiles on the Sanger Institute HPC,
you need to add `-profile singularity,sanger` to the Nextflow run parameters.

Here is a good example of the run script for using Sarek in the Wellcome Sanger Institute HPC:

```bash
#!/bin/bash
set -e
#BSUB -q "oversubscribed"
#BSUB -n 2
#BSUB -M 8G
#BSUB -R "select[mem>8G] rusage[mem=8G] span[hosts=1]"
#BSUB -o "sarek-%J-output.log"
#BSUB -e "sarek-%J-errors.log"

echo 'Load modules'
module load HGI/common/nextflow/25.04.6
module load cellgen/singularity

export NXF_OPTS='-Xms1G -Xmx8G -XX:+UseSerialGC'

run_name='haplotype_calling'

workdir="${run_name}.workdir"
run_parameters="$run_name.config.json"

echo Workdir: $workdir
echo Dataset: $run_name
echo Params:  $run_parameters

echo '=== Running Nextflow ==='

nextflow \
    -log ${run_name}.log \
    -config hgi.config \
    run https://github.com/nf-core/sarek -r 3.4.0 \
    -work-dir $workdir \
    -profile singularity,sanger \
    -params-file $run_parameters \
    -resume \
    -with-report ${run_name}.report.html \
    -with-trace ${run_name}.trace \
    -with-timeline ${run_name}.timeline.html
```


