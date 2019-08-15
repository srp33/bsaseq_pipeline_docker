#!/bin/bash

if [ ! -d InputData ]
then
    echo "InputData directory must have been created."
    exit 1
fi
if [ ! -d OutputData ]
then
    echo "OutputData directory must have been created."
    exit 1
fi

mkdir -p Temp

bash build_docker.sh

docker run --rm -i -t \
    -v "$(pwd)/InputData":"/InputData" \
    -v "$(pwd)/OutputData":"/OutputData" \
    -v "$(pwd)/Temp":"/Temp" \
    --user $(id -u):$(id -g) \
    srp33/bsaseq:version$(cat VERSION) \
    bash execute.sh \
        /InputData/for.fastq \
        /InputData/rev.fastq
