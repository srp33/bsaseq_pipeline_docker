FROM ubuntu:18.04
MAINTAINER Jacob Kelly

##install needed programs
ENV JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64/jre

RUN apt-get update -y && \
    apt-get install -y sickle bowtie2 samtools wget openjdk-8-jre-headless && \
    wget ftp://ftp.gramene.org/pub/gramene/CURRENT_RELEASE/fasta/zea_mays/dna/Zea_mays.B73_RefGen_v4.dna.toplevel.fa.gz && \
    gunzip -c Zea_mays.B73_RefGen_v4.dna.toplevel.fa.gz > B73.fasta && \ bowtie2-build -f B73.fasta "B73" && \ 
    wget https://sourceforge.net/projects/varscan/files/latest/download && \ mv download VarScan.jar && \
    wget http://sourceforge.net/projects/snpeff/files/snpEff_latest_core.zip && \ unzip snpEff_latest_core.zip && \ 
    wget execute.sh && \
    wget pileup_parser.pl && \
    wget README.txt

##when docker is used, run executable script on 2 input file, and return 1 zipped folder with files