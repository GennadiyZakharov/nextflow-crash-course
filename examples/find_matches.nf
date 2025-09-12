#!/usr/bin/env Nextflow
/*
***********************************************************************************
A small example of Nextflow workflow
It creates a big set of random data,
and finds in it lines containing the target substring
The matching process runs on split data - example of parallel data processing
************************************************************************************
*/

nextflow.enable.dsl=2 // DSL2 is the current standard of Nextflow syntax

// Default parameter input
// Inside the *.nf script we use parameter assignment
// The empty dictionary params = [:] exists in any Nextflow script by default
params.size = 5000000  // The size of random data to generate
params.chunkSize = 100000    // Number of lines in each chunk
params.target = 'Gen'       // The substring we want to find in the data


process randomdata { // Produces one file path - block of random data
    publishDir "results/randomdata" // We want to publish input data
    input:
        val size     // Input value: one integer
    script:
        outpath = "input_${size}.txt"   // I like to declare a variable for output and use it both in the script and in the output
        """
        cat /dev/urandom | base64 | fold -w 80 | head -n ${size} > ${outpath} || true
        """
    output:
        path (outpath, arity: '1') // Name of the file we have created
}

process split { // splits input file into chunks
    input:
        path (fileToSplit, arity: '1') // One file as input
    script:
        prefix = "input_chunk_"
        """
        mkdir {output}
        split -a 3 -d -l 50000 ${fileToSplit} ${prefix}
        """
    output:
        path "$prefix*" // Match all generated chunks
        // Here we emit the list of all files as a one element
}

process findMatches { // Finds lines that contain defined substring in a chunk
    tag "$chunk"
    input:
        // A good practice - pass all data to processes in channels
        // target - subsrting to find, path - file to search in
        tuple val(target), path(chunk, arity: '1')
    script:
        chunk_matches="${chunk}.matches.txt"
        """
        cat ${chunk} | grep '${target}' > "${chunk_matches}" || true
        """
    output:
        path (chunk_matches, arity: '1') // Match all set of generated files
}

process mergeResults { // combine into one file matched lines from all chunks
    publishDir "results/matches_merged"
    input:
        path chunks // All files in one
    script:
        matches='matches_merged.txt'
        """
        cat ${chunks} > ${matches}
        """
    output: 
        path matches // Match all set of generated files
}

/*
The workflow that can find matching lines in the input text

It splits input file into several chinks, process them in parallel
and merges final results int one file.
*/

workflow findMatchesInText{
    take: // the workflow accepts one input parameter - the channel containing input files
        target // The substring we're looking for - as a channel
        data   // The data to search
    main:
        println "findMatches workflow entry point reached"
        // we have only one data flow - perfect for using pipe notation
        // Each pipe is taking a channel and passing it to the next process or channel operator

        merged =
            data |              // input channel
            split |             // Process - split data file in several chunks
            flatten |           // Channel operator -  makes each chunk name a separate channel item
            combine(target) |   //  Channel operator - create tuples from the piped input and target
            map { c, t -> tuple(t, c) } | // Channel operator - reverse order of values in the tuple:  (chunk, target) -> (target, chunk)
            findMatches |       // Process - find matches in each chunk - parallel tasks
            collect |           // Channel operator - joins all items form the channel into one item
            mergeResults        // Process - merge all matches into one file
    emit:
        merged     // returning one file with merged lines
    // This block executes when the workflow completes - will be available only in Nextflow 25.10 :(
//    onComplete:
//        println "Finding string matches completed at: $workflow.complete"
//        println "Execution status: ${ workflow.success ? 'OK' : 'failed' }"
}

// The unnamed workflow is the default entry point for nextflow
workflow {
    // There is only main part - we don't need to declare it
    // Here we use function style for describing workflows
    data_size = Channel.of(params.size)   // Create a channel using parameter input
    target = channel.value(params.target) // Creating a channel that infinitely submits to the workflow the target substring
    // This is a recommended way to pass parameters to processes/workflows in Nextflow

    data = randomdata(data_size)             // Generate one random data file
    merged = findMatchesInText target,  data  // We can skip brackets because we have only one parameter
}
