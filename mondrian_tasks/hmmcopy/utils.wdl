version 1.0


task RunReadCounter{
    input{
        File bamfile
        File baifile
        Array[String] chromosomes
        String? singularity_dir
    }
    command<<<
        hmmcopy_utils readcounter --infile ~{bamfile} --outdir output -w 500000 --chromosomes ~{sep=" "chromosomes}
    >>>
    output{
        Array[File] wigs = glob('output/*.wig')
    }
    runtime{
        memory: "12 GB"
        cpu: 1
        walltime: "48:00"
        docker: 'quay.io/mondrianscwgs/hmmcopy:v0.0.4'
        singularity: '~{singularity_dir}/hmmcopy_v0.0.4.sif'
    }
}


task CorrectReadCount{
    input{
        File infile
        File gc_wig
        File map_wig
        String map_cutoff
        String? singularity_dir
    }
    command<<<
        hmmcopy_utils correct_readcount --infile ~{infile} --outfile output.wig \
        --map_cutoff ~{map_cutoff} --gc_wig_file ~{gc_wig} --map_wig_file ~{map_wig} \
        --cell_id $(basename ~{infile} .wig)
    >>>
    output{
        File wig = 'output.wig'
    }
    runtime{
        memory: "12 GB"
        cpu: 1
        walltime: "48:00"
        docker: 'quay.io/mondrianscwgs/hmmcopy:v0.0.4'
        singularity: '~{singularity_dir}/hmmcopy_v0.0.4.sif'
    }
}


task RunHmmcopy{
    input{
        File corrected_wig
        String? singularity_dir
    }
    command<<<
    hmmcopy_utils run_hmmcopy \
        --corrected_reads ~{corrected_wig} \
        --tempdir output \
        --reads reads.csv.gz \
        --metrics metrics.csv.gz \
        --params params.csv.gz \
        --segments segments.csv.gz \
        --output_tarball hmmcopy_data.tar.gz
    >>>
    output{
        File reads = 'reads.csv.gz'
        File reads_yaml = 'reads.csv.gz.yaml'
        File params = 'params.csv.gz'
        File params_yaml = 'params.csv.gz.yaml'
        File segments = 'segments.csv.gz'
        File segments_yaml = 'segments.csv.gz.yaml'
        File metrics = 'metrics.csv.gz'
        File metrics_yaml = 'metrics.csv.gz.yaml'
        File tarball = 'hmmcopy_data.tar.gz'
    }
    runtime{
        memory: "8 GB"
        cpu: 1
        walltime: "6:00"
        docker: 'quay.io/mondrianscwgs/hmmcopy:v0.0.4'
        singularity: '~{singularity_dir}/hmmcopy_v0.0.4.sif'
    }
}


task PlotHmmcopy{
    input{
        File segments
        File segments_yaml
        File reads
        File reads_yaml
        File params
        File params_yaml
        File metrics
        File metrics_yaml
        File reference
        File reference_fai
        String? singularity_dir

    }
    command<<<
        hmmcopy_utils plot_hmmcopy --reads ~{reads} --segments ~{segments} --params ~{params} --metrics ~{metrics} \
        --reference ~{reference} --segments_output segments.pdf --bias_output bias.pdf
     >>>
    output{
        File segments_pdf = 'segments.pdf'
        File bias_pdf = 'bias.pdf'
    }
    runtime{
        memory: "8 GB"
        cpu: 1
        walltime: "6:00"
        docker: 'quay.io/mondrianscwgs/hmmcopy:v0.0.4'
        singularity: '~{singularity_dir}/hmmcopy_v0.0.4.sif'
    }
}


task addMappability{
    input{
        File infile
        File infile_yaml
        String? singularity_dir
    }
    command<<<
    hmmcopy_utils add_mappability --infile ~{infile} --outfile output.csv.gz
    >>>
    output{
        File outfile = 'output.csv.gz'
        File outfile_yaml = 'output.csv.gz.yaml'
    }
    runtime{
        memory: "8 GB"
        cpu: 1
        walltime: "6:00"
        docker: 'quay.io/mondrianscwgs/hmmcopy:v0.0.4'
        singularity: '~{singularity_dir}/hmmcopy_v0.0.4.sif'
    }

}


task cellCycleClassifier{
    input{
        File hmmcopy_reads
        File hmmcopy_metrics
        File alignment_metrics
        String? singularity_dir
    }
    command<<<
    cell_cycle_classifier train-classify ~{hmmcopy_reads} ~{hmmcopy_metrics} ~{alignment_metrics} output.csv.gz

    echo "is_s_phase: bool" > dtypes.yaml
    echo "is_s_phase_prob: float" >> dtypes.yaml
    echo "cell_id: str" >> dtypes.yaml

    csverve rewrite --in_f output.csv.gz --out_f rewrite.csv.gz --dtypes dtypes.yaml --write_header

    >>>
    output{
        File outfile = 'rewrite.csv.gz'
        File outfile_yaml = 'rewrite.csv.gz.yaml'
    }
    runtime{
        memory: "18 GB"
        cpu: 1
        walltime: "6:00"
        docker: 'quay.io/mondrianscwgs/hmmcopy:v0.0.4'
        singularity: '~{singularity_dir}/hmmcopy_v0.0.4.sif'
    }

}

task addQuality{
    input{
        File hmmcopy_metrics
        File hmmcopy_metrics_yaml
        File alignment_metrics
        File alignment_metrics_yaml
        File classifier_training_data
        String? singularity_dir
    }
    command<<<
    hmmcopy_utils add_quality --hmmcopy_metrics ~{hmmcopy_metrics} --alignment_metrics ~{alignment_metrics} --training_data ~{classifier_training_data} --output output.csv.gz --tempdir temp
    >>>
    output{
        File outfile = "output.csv.gz"
        File outfile_yaml = "output.csv.gz.yaml"
    }
    runtime{
        memory: "8 GB"
        cpu: 1
        walltime: "6:00"
        docker: 'quay.io/mondrianscwgs/hmmcopy:v0.0.4'
        singularity: '~{singularity_dir}/hmmcopy_v0.0.4.sif'
    }
}

