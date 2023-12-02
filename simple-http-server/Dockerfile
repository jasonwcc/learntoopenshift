FROM registry.access.redhat.com/ubi9/ubi-minimal:latest

RUN microdnf install --nodocs -y socat iproute \
    && microdnf -y update \
    && microdnf clean all

RUN mkdir /www/ && chmod 770 /www/

ADD srv.sh /www/srv.sh

EXPOSE 8080

USER 1984

CMD socat TCP4-LISTEN:8080,fork EXEC:/www/srv.sh
