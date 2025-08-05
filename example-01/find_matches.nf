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
    publishDir "results/produce"
    input:
        val size
    script:
        outFile = "input_${size}.txt"
        """
        cat /dev/urandom | base64 | fold -w 80 | head -n ${size} > ${outFile} || true
        """
    output:
        path outFile
}

process split {
    input:
        path fileToSplit // One file as input
    script:
        outputPrefix="input_split_"
        """
        mkdir {output}
        split -a 3 -d -l 50000 ${fileToSplit} ${outputPrefix}
        """
    output:
        path "${outputPrefix}*" // Match all set of generated files
}

process findMatches {
    publishDir "results/matched"
    tag "$chunk"
    input:
        path chunk // One file as input
    script:
        outChunk="${chunk}.matches.txt"
        """
        cat ${chunk} | grep 'Gen' > "${outChunk}" || true
        """
    output:
        path outChunk // Match all set of generated files
}

process mergeResults {
    publishDir "results/matched_merged"
    input:
        path chunks // All files in one
    script:
        mergedMatches="matches_merged.txt"
        """
        cat ${chunks} > "$mergedMatches"
        """
    output:
        path mergedMatches // Match all set of generated files
}

// Workflow block
workflow {
    data_size = channel.of(params.size)   // Create a channel using parameter input
    data = produce(data_size)             // Create one path - data file
    chunks = split(data)                  // split initial data file in several chunks
    chunks_sep = chunks.flatten() // The chunks output is emitted as a single element.
    // The flatten() operator splits this combined element so that each file is treated as a sole element.
    matches = findMatches(chunks_sep) // find matches in each chunk - parallel
    merged = mergeResults(matches) // TODO add merging
}
