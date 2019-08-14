FROM ubuntu:18.04

ENV JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64/jre

RUN apt-get update -y && \
    apt-get install -y zip unzip sickle bowtie2 samtools wget openjdk-8-jre-headless && \
    wget "ftp://ftp.gramene.org/pub/gramene/CURRENT_RELEASE/fasta/zea_mays/dna/Zea_mays.B73_RefGen_v4.dna.toplevel.fa.gz" && \
    gunzip -c Zea_mays.B73_RefGen_v4.dna.toplevel.fa.gz > B73.fasta && \ 
    bowtie2-build -f B73.fasta "B73" && \ 
    wget -O VarScan.jar "https://sourceforge.net/projects/varscan/files/latest/download" && \ 
    wget "http://sourceforge.net/projects/snpeff/files/snpEff_latest_core.zip" && \ 
    unzip snpEff_latest_core.zip && \
    rm snpEff_latest_core.zip

ADD execute.sh /
ADD pileup_parser.pl /

WORKDIR /

#CMD ["/execute.sh"]
