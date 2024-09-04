params.debug = false

process POSTCODE {
    debug params.debug
    tag "${meta.id}"
    cache true

    cpus 1

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'bioinfotongli/postcode:latest':
        'bioinfotongli/postcode:latest'}"
    publishDir params.out_dir + "/PoSTcode_decoding_output"

    input:
    tuple val(meta), file(spot_profile), file(spot_loc), file(codebook), file(readouts)

    output:
    tuple val(meta), path("${out_name}"), emit:decoded_peaks
    tuple val(meta), path("${prefix}_decode_out_parameters.pickle"), optional: true
    path "versions.yml"           , emit: versions

    script:
    prefix = meta.id ?: "none"
    out_name = "${prefix}_decoded_spots.csv"
    def args = task.ext.args ?: ""
    """
    /scripts/decode.py run --spot_profile_p ${spot_profile} --spot_locations_p ${spot_loc} \\
        --codebook_p ${codebook} --out_name ${out_name} --readouts_csv ${readouts} \\
        ${args}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        : \$(echo \$(/scripts/decode.py version ))
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    out_name = "${prefix}_decoded_spots.csv"
    """
    touch ${out_name}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        postcode: \$(/scripts/decode.py version //')
    END_VERSIONS
    """
}