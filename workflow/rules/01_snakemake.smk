###############################################################################
#About: Testing the eRI, in anger
#
#
###############################################################################

configfile: "config/config.yaml"

#localrules: create_small_files, create_large_file

rule all:
	input:
		expand("results/create_small_files_{batch}.log", batch=range(1,11)),
		expand("results/create_large_file_{large_batch}.log", large_batch=range(1,5))

rule create_small_files:
	output:
		logfile = "results/create_small_files_{batch}.log",
		tempdir = temp(directory("results/create_small_files_{batch}"))
	threads:
		1
	resources:
		mem_mb = 1024*2,
		runtime = 5
	shell:
		"""
		set -euo pipefail
		start=$(date +%s)
		echo "$(hostname): Creating small files for batch {wildcards.batch}..." > {output.logfile}
		mkdir -p {output.tempdir}
		for i in $(seq 1 10); do
			echo $i > {output.tempdir}/file_$i.txt
		done
		end=$(date +%s)
		echo "Small file creation completed in $((end-start)) seconds" >> {output.logfile}
		echo "Created 10 files in {output.tempdir}" >> {output.logfile}
		"""


rule create_large_file:
	output:
		logfile = "results/create_large_file_{large_batch}.log",
		largefile = temp("results/largefile_{large_batch}")
	threads:
		1
	resources:
		mem_mb = 1024*4,
		runtime = 5
	shell:
		"""
		set -euo pipefail
		start=$(date +%s)
		echo "$(hostname): Creating large file for batch {wildcards.large_batch}..." > {output.logfile}
		echo "Target file: {output.largefile}" >> {output.logfile}
		dd if=/dev/zero of={output.largefile} bs=1M count=1024 status=none
		end=$(date +%s)
		file_size=$(du -h {output.largefile} | cut -f1)
		echo "Large file creation completed in $((end-start)) seconds" >> {output.logfile}
		echo "Created file size: $file_size" >> {output.logfile}
		echo "Write speed: $(echo "scale=2; 1024/$((end-start))" | bc -l) MB/s" >> {output.logfile}
		"""
