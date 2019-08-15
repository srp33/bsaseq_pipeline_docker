#!/bin/bash

#variable created to abbreviate program calls
ID="currentProject"

###trim Illumina adapters off
# -f indicates forward reads, -r reverse reads, -o output/trimmed forward reads -p output/trimmed reverse reads -s output/trimmed singleton reads -t indicates the quality scoring scheme (phred)
sickle pe -f $1 -r $2 -o trimmed-for.fastq -p trimmed-rev.fastq -s trimmed.s.fastq -t sanger

###Align data to reference genome
# variables created to abbreviate code in next program call
FASTQ1="trimmed-for.fastq"
FASTQ2="trimmed-rev.fastq"
# -x indicates reference genome --phred33 indicates quality scoring scheme -1 indicates forward reads -2 indicates reverse reads -S specifies output is to be a .sam file
bowtie2 -x "./B73" --phred33 -1 ${FASTQ1} -2 ${FASTQ2} -S ${ID}.sam

###Convert from .sam to .bam, sort and index
#variable created to abbreviate program call
REF="./B73.fasta"
#view allows us to take the alignment information in ${ID}.sam and output it to the sort function
# -b output is in the bam format -u the output is uncompressed (desirable since we're piping it into the next function) -T specifies a fasta format reference file
#sort sorts reads by leftmost coordinate. -O specifies output file format -o specifies output file to write to
samtools view -bu -T ${REF} ${ID}.sam | samtools sort -O bam -o ${ID}_sorted.bam -

#cleaning up a bit. If the above worked, delete the HUGE sam file, we have a sorted bam.
if [ $? -eq 0 ]
then
	rm ${ID}.sam
	chmod 444 ${ID}_sorted.bam
fi
#indexing our file allows for faster accession of data
samtools index ${ID}_sorted.bam

###Create pileup file, which reorganizes the data by genomic position and have columns with info in the reads at that position, rather than having the reads organized by read (as in the .bam)
#-f specifies the reference genome -o specifies the output file
samtools mpileup -f ${REF} -o ${ID}.pileup ${ID}_sorted.bam

###Filter pileup
# pileup_parser.pl obtained as part of a suite of tools downloaded from https://github.com/galaxyproject/tools-devteam
#the following variables are used in place of magic numbers in the next program call
#die "Usage: pileup_parser.pl <in_file> <ref_base_column> <read_bases_column> <base_quality_column> <coverage column> <qv cutoff> <coverage cutoff> <SNPs only?> <output bed?> <coord_column> <out_file> <total_diff> <print_qual_bases>\n" unless @ARGV == 13;
INPUT_PILEUP="${ID}.pileup" #my $in_file = $ARGV[0];
REF_BASE_COL=3 #my $ref_base_column = $ARGV[1]-1; # 1 based
READ_BAD_COL=5 #my $read_bases_column = $ARGV[2]-1; # 1 based
BASE_QUAL_COL=6 #my $base_quality_column = $ARGV[3]-1; # 1 based
COVERAGE_COL=4 #my $cvrg_column = $ARGV[4]-1; # 1 based
QUAL_CUTOFF=30 #my $quality_cutoff = $ARGV[5]; # phred scale integer
COVERAGE_CUTOFF=3 #my $cvrg_cutoff = $ARGV[6]; # unsigned integer
SNPS_ONLY="Yes" #my $SNPs_only = $ARGV[7]; # set to "Yes" to print only positions with SNPs; set to "No" to pring everything
BED_FORMAT="No" #my $bed = $ARGV[8]; #set to "Yes" to convert coordinates to bed format (0-based start, 1-based end); set to "No" to leave as is
COORD_COL=1 #my $coord_column = $ARGV[9]-1; #1 based 
OUTPUT_FILE="${ID}_filtered.pileup" #my $out_file = $ARGV[10];
TOTAL_DIFF="Yes" #my $total_diff = $ARGV[11]; # set to "Yes" to print total number of deviant based
PRINT_QUAL_BASES="Yes" #my $print_qual_bases = $ARGV[12]; #set to "Yes" to print quality and read base columns

./pileup_parser.pl \
	${INPUT_PILEUP} \
	${REF_BASE_COL} \
	${READ_BAD_COL} \
	${BASE_QUAL_COL} \
	${COVERAGE_COL} \
	${QUAL_CUTOFF} \
	${COVERAGE_CUTOFF} \
	${SNPS_ONLY} \
	${BED_FORMAT} \
	${COORD_COL} \
	${OUTPUT_FILE} \
	${TOTAL_DIFF} \
	${PRINT_QUAL_BASES}


###Filter based on coverage and add 13th column with frequency of deviants
#variables created to abbreviate program calls
FILTERED_PILEUP="${ID}_filtered.pileup"
FILTERED_PILEUP_HIGH_CVRG="${ID}_pileup-filtered_cvrg-4.tsv"
#column $11 has the coverage at each position. If there isn't a coverage of at least 4, the data isn't used. Additionally, the frequency of deviation from the reference genome is calculated by taking the total number of deviants (column 12) and dividing by the total number of reads (column 11) 
awk 'BEGIN{FS="\t";OFS="\t"}{ if ( $11 >= 4) { $13 = ($12 / $11); print $0 } }' ${FILTERED_PILEUP} > ${FILTERED_PILEUP_HIGH_CVRG}
# FILTERED PILEUP COLUMNS (first 12 columns come from pileup_parser.pl, the 13th comes from the awk function on the previous line)
# 01 Chr
# 02 Pos (1-based)
# 03 Ref base
# 04 Coverage
# 05 Bases within read
# 06 Quality values (phred33)
# 07 Num A variants
# 08 Num C variants
# 09 Num G variants
# 10 Num T variants
# 11 Quality adjusted coverage
# 12 Total number of deviants
# 13 Frequency of deviants (we're adding this column in this script)


###Bowtie2 allows for ambiguous base pairs in the reference genome, and when aligning to the reference genome. This step removes these ambiguous bases (false positives) from the data set

FILTERED_PILEUP_BASE_NAME="${ID}_pileup-filtered_cvrg-4"
FILTERED_PILEUP="${FILTERED_PILEUP_BASE_NAME}.tsv"

awk '$2!=N{print $0}' > "${FILTERED_PILEUP}"
#This is where you would plot graphs

for i in {1..10}; do
#Split by chromosome
	awk "\$1==${i}{print \$0}" "${FILTERED_PILEUP}" > ${FILTERED_PILEUP_BASE_NAME}_chr${i}.tsv
#VarScan filters based upon homozygosity. mpileup2cns means it takes in a mpileup formatted file and runs a consensus analysis. --min-coverage is the minimum read depth. --min-var-freq is the minimum variant allele frequency threshold. --p-value is the p value threshold for calling variants 
	java -jar VarScan.jar mpileup2cns ${FILTERED_PILEUP_BASE_NAME}_chr${i}.tsv --min-coverage 4 --min-var-freq 0.5 --p-value 0.99 > chr${i}.vcf
#99.9% of the time, EMS produces mutations by changing C -> T or G -> A. This awk command filters the data to contain just those base pair deviations
	awk '{if($3=="C" && $4=="T") print $0; else if ($3=="G" && $4=="A") print $0}' chr${i}.vcf > chr${i}_EMS.vcf
#runs snpEff program, which analyzes the data and produces output files containing information on the effect the SNPs have. The snpEff_summary.html contains a summary of the information. The snpEff_genes.txt contains the information of interest - mutations in genes and their predicted effects. The output file specified in the program call contains additional information that may be useful to users.
	java -jar snpEff/snpEff.jar Zea_mays chr${i}_EMS.vcf > snpEff_chr${i}_EMS.vcf
	mv snpEff_summary.html snpEff_summary_chr${i}_EMS.html
	mv snpEff_genes.txt snpEff_genes_chr${i}_EMS.txt
#awk command to pull out all of the high impact variants and place them in their own data file
	awk '{if($5>0) print$0;}' snpEff_genes_chr${i}_EMS.txt > snpEff_HIGH_IMPACT_genes_only_chr${i}_EMS.txt
#awk command to pull out all of the moderate impact variants that were not high impact variants and place them in their own data file
	awk '{if($5==0 && $6>0) print$0;}' snpEff_genes_chr${i}_EMS.txt > snpEff_MODERATE_IMPACT_genes_chr${i}_EMS.txt
#add awk command to sort high, moderate, and low in genes file	
done
zip folder ${FILTERED_PILEUP_BASE_NAME}* snpEff_* README
mv folder /outputDir/OutData
