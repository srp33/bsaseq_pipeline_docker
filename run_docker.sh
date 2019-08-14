#!/bin/bash

# This should be an existing directory that has FASTQ files in it.
# Must be an absolute path
#inputDir=/path/on/linux/computer/input

# First create output directory (outside the container)
# Must be an absolute path
#outputDir=/path/on/linux/computer/output
# mkdir -p $outputDir

docker run --rm -i -t \
  -v "$inputDir":"/InputData" \
  -v "$outputDir":"/OutputData" \
  --user $(id -u):$(id -g) \
  srp33/bsaseq:version$(cat VERSION) \
  /bin/bash
