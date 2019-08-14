#! /bin/bash

set -o errexit

tag=version$(cat VERSION)

docker build -t srp33/bsaseq:$tag .

##docker login -u=srp33
#docker push srp33/bsaseq
