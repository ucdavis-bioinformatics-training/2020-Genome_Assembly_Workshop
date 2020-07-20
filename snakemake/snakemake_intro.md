# Snakemake Introduction

1. Overview
2. Initial Setup
3. Brief Overview of Commands Using the Example Workflow
4. Challenge activities and CLI/cluster warmup
5. Using the config file
6. Running the snakefile as a job on the cluster 

## Overview

Snakemake is a flexible, python based workflow system. 
   - Workflows are sets of rules. (e.g `rule assembly:`)
   - Rule dependencies are determined in a systematic fashion by creating a directed acyclic graph (DAG) with the 
    ability of running rules in parallel. 
   - Each rule can consist of one or more of the following parts:
        + `input:` These files must be present for a rule to execute.
        + `output:` These files must be present following the execution of a rule for it to be considered "successful".
        + `shell:` or `run:` This is the code to be executed. Use shell for pure BASH or run for Pythonic implementations.
            - I prefer to use `run:` here while calling `shell()` within the python to implement BASH
        + `params:` Further specify variables for the use in `shell:` or `run:`' 
   - Wildcards can be used to expand rules across multiple samples along with the (e.g: `expand('somedir/{sample}.txt, sample=SAMPLES)`)
   - `input:`, `output:`, and `params:`" are accessible in the `shell:` or `run:` statements. 

Snakemake is different from other workflow systems (like CWL-Common workflow language) in the following ways:
   - Extension of python, which is a readable and user friendly language. 
   - Integrates with Conda allowing for easy reproducibility of environments. 
   - Workflow flexibility scales for running locally to HPC systems with ease.   


## Initial Setup

- Make sure you have a directory in the workshop folder (`/share/workshop/$USER`):
    ```
    mkdir /share/workshop/$USER
    ```

- Copy the materials for the intro and the tutorial:
    ``` 
    cd /share/workshop/$USER
    mkdir snakemake-demo
    cp -r /share/biocore/workshops/Genome-Assembly-Workshop-Jun2020/snakemake-demo/* snakemake-demo/
    cd snakemake-demo
    ```
  
  
- Now lets see what files we have here:

<div class="output">keithgmitchell@barbera:/share/biocore/keith/examples/snakemake-demo$ ls
config.json  data  envs  scripts  slurm-24072402.out  Snakefile
</div>

 - data = mock data for the snakefile to use
 - Snakefile = name of the snakemake "formula" file
    - Note: The default file that snakemake looks for in the current working directory is the `Snakefile`. If you would like to 
    override that you can specify it following the `-s`
        - `snakemake -s snakefile.py`
 - envs = directory for storing the conda environments that the workflow will use. 
 - scripts = directory for storing python scripts called by the snakemake formula.
 - config.json = json format file with extra parameters for our snakemake file to use.
 - cluster.json = json format file with specification for running on the HPC
 - samples.txt = file we will use later relating to the config.json file. 
 
Let's look at the contents of the `Snakefile` and talk a bit about what it is doing. 

<pre class="prettyprint"><code class="language-py" style="background-color:333333">

samples = ["A", "B"]

rule all:
    input:
        "calls/all.vcf",
        "plots/quals.svg"

rule bwa:
    input:
        "data/genome.fa",
        "data/samples/{sample}.fastq"
    output:
        temp("mapped/{sample}.bam")
    threads: 8
    shell:
        "module load bwa; "
        "bwa mem -t {threads} {input} | samtools view -Sb - > {output}"

rule sort:
    input:
        "mapped/{sample}.bam"
    output:
        "mapped/{sample}.sorted.bam"
    shell:
        "module load samtools; "
        "samtools sort -o {output} {input}"

rule call:
    input:
        fa="data/genome.fa",
        bam=expand("mapped/{sample}.sorted.bam", sample=samples)
    output:
        "calls/all.vcf"
    shell:
        "module load samtools; "
        "module load bcftools; "
        "samtools mpileup -g -f {input.fa} {input.bam} | "
        "bcftools call -mv - > {output}"

rule stats:
    input:
        "calls/all.vcf"
    output:
        report("plots/quals.svg", caption="report/calling.rst")
    conda:
        "envs/stats.yaml"
    script:
        "scripts/plot-quals.py"


</code></pre>

 
## Brief Overview of Commands Using the Example Workflow

1. Prepare the environment for running snakemake:
    ```
    module load snakemake/5.6.0
    source activate snakemake
    ```
**Note**: if you have trouble with the `source activate snakemake` command try the following:
    ```
    conda init bash
    source ~/.bashrc
    ```
2. Run the snakemake file as a dry run (the example workflow shown above). 
    - This will build a DAG of the jobs to be run without actually executing them.
    - `snakemake --dry-run`
    - Why is this helpful?

3. Executing rules of interest. 
    - `snakemake --dry-run all` VS. `snakemake --dry-run call` VS. `snakemake --dry-run bwa`
    - Why does this happen.. where is the wildcard specified?
    
4. Run the snakemake file in order to produce an image of the DAG of jobs to be run.
    - `snakemake --dag | dot -Tsvg > dag.svg` OR `snakemake --dag | dot -Tsvg > dag.svg`
        <img src="dag.svg" alt="dag" height="500px" width="300px"/>

5. Run the snakemake (this time not as a dry run)
    - `snakemake --use-conda`


## Challenge activities and CLI/cluster warmup:
Please attempt the advanced questions but do not worry if they are too difficult. 
Send a private message to me on Slack with your answers and raise your hand on zoom when you are finished. 


1. Access the svg file from the cluster to your local computer to view it yourself after running the `--dag` command.
 Just tell me the program or command you used to do this. **(5 mins)**
2. Edit the `Snakefile` to include all three samples. (Hint: look at `data/samples` to see which one can still be included) Then rerun the `Snakefile`.  **(7 mins)**
    - It may say "Nothing to be done." Why is this and how can you overcome it? (For example try first starting by removing the plots and see what happens)
3. Which lines on the above `Snakefile` would not work on an HPC? (Hint: why is the stats rule not this way?) **(5 mins)**
4. Advanced: We now have a graph of the vcf quality scores but not we may want to do some more advanced analysis with the vcf file. 
Create a rule in the snakemake file that strips the header from the vcf file (lines with '##' in it) so we are only left with a tsv. 
Now run just the snakemake and specify just that rule you have just created. Why does running the snakemake with this rule not produce any plots?
How can you adjust the all rule to run this new rule and the plot rule? **(15 mins)**
5. Advanced: Use the snakemake documentation or google to find out how to remove not store the sorted mappings. Then implement this in the file above, clean the files, and rerun. (Hint: we also use this in the snakefile above). **(7 mins)**


## Using the config file. 
We are going to run a small example of how we can use the config file to increase the robustness of our Snakefile:

Let't take a look at the cofig file (config.json):
<pre class="prettyprint"><code class="language-py" style="background-color:333333">
 {
     "__default__" :
     {
         "samples_file" : "samples.txt",
     },
 }
</code></pre>

Replace `samples = ["A", "B"]` with the following and clean up your files (`rm -rf calls/ mapped/ plots/`):

<pre class="prettyprint"><code class="language-py" style="background-color:333333">
import json
import sys
samples = []
with open(config["__default__"]['samples_file'], 'r') as samples_file:
    for line in samples_file:
        if line.strip('\n') != '':
            samples.append(line.strip('\n'))
print(samples)
</code></pre>
Then run the snakefile specifying the custom parameters in our json file. 
```
snakemake --use-conda --configfile config.json
```



## Running the snakefile as a job on the cluster and using the config file
Let's look at a couple of ways we can run the snakemake workflow on the cluster. The first one shown here runs one job on the cluster 
that will then execute the `snakemake --use-conda` command. This does not fully utilize the capability 
of snakemake's ability. Go ahead and run this command. 
```
sbatch -t 1:00:00 -n 1 --ntasks 1 --mem 2000 --wrap='snakemake --use-conda'
```

After running the command above and your job has finished running, clean up the files (`rm -rf mapped/ calls/ plots/`) and run the line below. 
Running the sbatch within snakemake allows for a more control over your resources for each rule in the pipleine.
We will use the `config.json` file, as seen below, for this:

```
snakemake -j 99 --cluster-config cluster.json --cluster "sbatch -t {cluster.time} --output {cluster.output} --error {cluster.error} --nodes {cluster.nodes} --ntasks {cluster.ntasks} --cpus-per-task {cluster.cpus} --mem {cluster.mem}" --use-conda --latency-wait 50
```

<pre class="prettyprint"><code class="language-py" style="background-color:333333">
{
    "__default__" :
    {
        "A" : "overall",
        "time" : "1:00:00",
        "nodes": 1,
        "ntasks": 1,
        "cpus" : 1,
        "p" : "standard",
        "mem": 2000,
        "output": "snakemake%A.out",
        "error": "snakemake%A.err"
    }
}
</code></pre>

What do you notice about the difference between the two? 

Note: In my experience this can be a bit tricky, and it is not something, I myself, have entirely mastered, but I encourage working to get more comfortable with it! 
    

## Extra resources:
[Snakemake Documentation Homepage](https://snakemake.readthedocs.io/en/stable/index.html)



