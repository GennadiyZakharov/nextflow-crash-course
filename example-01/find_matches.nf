/*
***********************************************************************************
A small example of Nextflow workflow
It creates a big set of random data,
and finds in it lines containing 'Gen' substring
The matching process runs on split data - example of parallel data processing
************************************************************************************
*/

// Default parameter input
// Inside the *.nf script we use parameter assignment
// The empty dictionary params = [:] exists in any Nextflow script by default
params.size = 1000000  // The size of random data to generate
params.chunkSize = 50000    // Number of lines in each chunk

process randomdata { // Produces one file path - block of random data
    publishDir "results/randomdata" // We want to publish input data
    input:
        val size     // Input value: one integer
    script:
        outpath = "input_${size}.txt"
        """
        cat /dev/urandom | base64 | fold -w 80 | head -n ${size} > ${outpath} || true
        """
    output:
        path (outpath, arity: '1') // Output: one path to a file
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
        path "$prefix*" // Match all set of generated files
        // Here we emit list of all files as a one element in the channel
}

process findMatches { // Finds lines that contain defined substring in a chunk
    tag "$chunk"
    input:
        path(chunk, arity: '1') // One file as input
    script:
        chunk_matches="${chunk}.matches.txt"
        """
        cat ${chunk} | grep 'Gen' > "${chunk_matches}" || true
        """
    output:
        path (chunk_matches, arity: '1') // Match all set of generated files
}

process mergeResults { // combine in one file matched lines from all chunks
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
        data
    main:
        // we have only one data flow - perfect for using pipe notation
        merged =
            data |         // input channel
            split |        // split(data)        // split data file in several chunks
            flatten |      // Channel.flatten()  // makes each chunk name a separate channel item
            findMatches |  // findMatches()      // find matches in each chunk - parallel tasks
            collect |      // Channel.collect()  // joins all items form the channel into one item
            mergeResults   // mergeResults()     // Merge all matches into one file
    emit:
        merged
}

// The unnamed workflow is the default entry point for nextflow
workflow {
    // There is only main part - so wen don't need to declare it
    // Here we use standard way for describing workflows declaring channels
    data_size = Channel.of(params.size)   // Create a channel using parameter input
    data = randomdata(data_size)             // Generate one random data file
    merged = findMatchesInText data  // We can skip brackets because we have only one parameter
}
