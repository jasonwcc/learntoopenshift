#!/usr/bin/env bash

# https://github.com/containers/buildah
# https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html-single/building_running_and_managing_containers/index?extIdCarryOver=true&sc_cid=7013a000002peuMAAQ#proc_using-the-ubi-micro-images_assembly_types-of-container-images
set -x

buildah pull registry.access.redhat.com/ubi9/ubi-micro:latest

microcontainer=$(buildah from registry.access.redhat.com/ubi9/ubi-micro:latest)


micromount=$(buildah mount $microcontainer)

yum install \
    --installroot $micromount \
    --releasever 9 \
    --setopt install_weak_deps=false \
    --nodocs -y \
    socat iproute curl
yum clean all \
    --installroot $micromount

mkdir ${micromount}/www
chmod 770 ${micromount}/www
cp -v srv.sh ${micromount}/www/srv.sh

buildah umount $microcontainer

buildah config \
    --annotation "build.host=$(uname -n)" \
    --port 8080 \
    --user 1984 \
    --cmd "socat TCP4-LISTEN:8080,fork EXEC:/www/srv.sh" \
    "$microcontainer"


buildah commit $microcontainer quay.io/openshift-examples/simple-http-server:micro



