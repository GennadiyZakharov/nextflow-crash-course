/*
The first working example of Nextflow workflow
It cheated a big set of random data, 
and fings in it lines containing 'Gen' substring
The matching process runs on splitted data - example of parallel data processing

The workflow contains extended comments explaining main Nextflow camabilities
*/

// Nextflow - groovy script
// 

// Default parameter input
// Here we automatically initialize the empty dictionary params = [:]
// settign default parameters
params.size=1000000  // The size of random data to generate
params.chunkSize=50000    // Number of lines in each chunk

// This process produces one file path - block of random data
process produce {
    publishDir "results/produce" // We want to publish input data - see details in the docs

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

process split {
    publishDir "results/split"
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

process findMatches {
    publishDir "results/matched"
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

process mergeResults {
    publishDir "results/matched_merged"
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


workflow findMatchesInText{
    /*
    This test worflow parses an pnput file and finds in it all lines
    that contain some specific substring

    It splits input file into several chinks, process them in parallel
    and merges final results int one file.
    */

    take: // the workflow accepts one input parameter - the channel containing input files
        data
    main:
        chunks = split(data)              // split data file in several chunks
        chunks_sep = chunks.flatten()     // .flatten() makes each file name a separate channel item
        matches = findMatches(chunks_sep) // find matches in each chunk - parallel tasks
        all_matches = matches.collect()   // .collect() joins all items form the channel into one item
        merged = mergeResults(all_matches)// Merge all matches into one file
    emit:
        merged
}

// The unnamed workflow is the default entry point for nextflow
workflow {
    // There is only main part - so wen don't need to declare it
    data_size = channel.of(params.size)   // Create a channel using parameter input
    data = produce(data_size)             // Generate one random data file
    merged = findMatchesInRandomText(data_size) // Skip brackets because we have no parameters
}
