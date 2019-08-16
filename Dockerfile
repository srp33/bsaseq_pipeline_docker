FROM ubuntu:18.04

ENV JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64/jre
ENV TZ=US
ENV MINICONDA_VERSION=4.6.14
ENV PATH="/miniconda/bin:${PATH}"
ENV THREADS=32

RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime \
 && echo $TZ > /etc/timezone \
 && apt-get update -y \
 && apt-get install -y zip unzip wget curl sickle \
    openjdk-8-jre-headless build-essential zlib1g-dev locales \
 && locale-gen en_US.UTF-8 \
 && curl -LO http://repo.continuum.io/miniconda/Miniconda3-${MINICONDA_VERSION}-Linux-x86_64.sh \
 && bash Miniconda3-${MINICONDA_VERSION}-Linux-x86_64.sh -p /miniconda -b \
 && rm Miniconda3-${MINICONDA_VERSION}-Linux-x86_64.sh \
 && conda config --add channels bioconda \
 && conda config --add channels conda-forge \
 && conda install samtools=1.9 bowtie2=2.3.5

RUN mkdir /genome \
 && wget -O /genome/Zea_mays.B73_RefGen_v4.dna.toplevel.fa.gz "ftp://ftp.gramene.org/pub/gramene/CURRENT_RELEASE/fasta/zea_mays/dna/Zea_mays.B73_RefGen_v4.dna.toplevel.fa.gz" \
 && cd /genome \
 && gunzip -c Zea_mays.B73_RefGen_v4.dna.toplevel.fa.gz > B73.fasta \ 
 && rm Zea_mays.B73_RefGen_v4.dna.toplevel.fa.gz \ 
 && bowtie2-build --threads $THREADS -f B73.fasta "B73" \
 && cd / \
 && chmod 777 /genome -R

RUN wget -O VarScan.jar "https://sourceforge.net/projects/varscan/files/latest/download" \ 
 && wget "http://sourceforge.net/projects/snpeff/files/snpEff_latest_core.zip" \ 
 && unzip snpEff_latest_core.zip \
 && rm snpEff_latest_core.zip
# TODO: Download the snpEff database for Zea_mays here.

ADD execute.sh /
ADD pileup_parser.pl /

WORKDIR /
