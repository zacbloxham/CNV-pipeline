for file in ./fastq_sequences/*_R1.fastq; do

	filename=$(echo "${file##*/}" | cut -d "_" -f 1,2,3)

	bowtie2 \
		-p 2 \
		-k 5 \
		-x ../hg19/bowtie_indx/hg19_bowtie_indx \
		-1 ../fastq_sequences/${filename}_R1.fastq -2 ../fastq_sequences/${filename}_R2.fastq \
		-S ./alignments/${filename}.sam \

	samtools view -S -b ./alignments/${filename}.sam > ./alignments/${filename}.unsorted.bam
	rm *.sam
	samtools sort ./alignments/${filename}.unsorted.bam -o ./alignments/${filename}.sorted.bam
	rm *.unsorted.bam
	sambamba markdup -r ./alignments/${filename}.sorted.bam ./alignments/${filename}.filtered.bam
	rm *.sorted.bam
	samtools index ./alignments${filename}.filtered.bam

	python ./conifer_v0.2.2/conifer.py rpkm \
		--probes ./probes/panel.txt \
		--input  ./alignments/${filename}.filtered.bam \
		--output ./RPKM/${filename}.rpkm.txt \

	python ./conifer_v0.2.2/conifer.py analyze \
		--probes ./probes/panel.txt \
		--rpkm_dir ./RPKM/ \
		--output ./calls/analysis.hdf5
		--svd 2

	python ./conifer/conifer_v0.2.2/conifer.py call\
		--input ./calls/analysis.hdf5
		--output ./calls/calls.txt
		--threshold 1 
done
