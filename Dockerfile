FROM ubuntu:latest
#MAINTAINER LasLabs Inc <support@laslabs.com>

# Install
RUN cat /etc/apt/sources.list | sed s/archive.ubuntu.com/ubuntu.c3sl.ufpr.br/ > teste \
    && cp teste /etc/apt/sources.list \
    && apt update \
    && rm -rf /etc/samba \
    && rm -rf /var/lib/samba \
    && rm -rf /var/log/samba \
    && mkdir -p /samba/etc \
    && mkdir -p /samba/lib \
    && mkdir -p /samba/log \
    && ln -s /samba/etc /etc/samba \
    && ln -s /samba/lib /var/lib/samba \
    && ln -s /samba/log /var/log/samba
RUN apt -y install samba krb5-config winbind smbclient bind9 \
    && rm -rf /etc/samba/smb.conf

# Expose ports
EXPOSE 37/udp \
       53 \
       88 \
       135/tcp \
       137/udp \
       138/udp \
       139 \
       389 \
       445 \
       464 \
       636/tcp \
       1024-5000/tcp \
       3268/tcp \
       3269/tcp

# Persist the configuration, data and log directories
VOLUME ["/samba"]

# Copy & set entrypoint for manual access
COPY ./docker-entrypoint.sh /
COPY ./named.conf /etc/named/named.conf
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["samba"]

# Metadata
#ARG BUILD_DATE
#ARG VCS_REF
#ARG VERSION
#LABEL org.label-schema.build-date=$BUILD_DATE \
#      org.label-schema.name="Samba DC - Alpine" \
#      org.label-schema.description="Provides a Docker image for Samba 4 DC on Alpine Linux." \
#      org.label-schema.url="https://laslabs.com/" \
#      org.label-schema.vcs-ref=$VCS_REF \
#      org.label-schema.vcs-url="https://github.com/LasLabs/docker-alpine-samba-dc" \
#      org.label-schema.vendor="LasLabs Inc." \
#      org.label-schema.version=$VERSION \
#      org.label-schema.schema-version="1.0"
