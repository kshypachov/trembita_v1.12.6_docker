FROM ubuntu:18.04 AS base
ENV DEBIAN_FRONTEND=noninteractive

LABEL authors="Kirill Shypachov @kshypachov"
ARG REPO_KEY=https://project-repo.trembita.gov.ua:8081/public-keys/public.key.txt


RUN apt-get -qq update
RUN apt-get -qq install gnupg2 \
    && apt-get -qq --no-install-recommends install \
      locales ca-certificates perl bzip2 libc6-dev lsb-release \
      ca-certificates gnupg supervisor net-tools iproute2 locales \
      rlwrap ca-certificates-java \
      crudini adduser expect curl rsyslog dpkg-dev \
    && echo "LC_ALL=en_US.UTF-8" >>/etc/environment \
    && locale-gen en_US.UTF-8 \
    && apt-get clean  \
    && rm -rf /var/lib/apt/lists/*

RUN sed -i 's/^[A-Za-z0-9]/#&/' /etc/apt/sources.list
RUN echo "deb https://project-repo.trembita.gov.ua:8081/repository/ss-1.12.6/ bionic main" | tee -a /etc/apt/sources.list
RUN echo "deb https://project-repo.trembita.gov.ua:8081/repository/trembita-member_archive/ certified main" | tee -a /etc/apt/sources.list

ADD ["$REPO_KEY","/tmp/repokey.gpg"]
RUN apt-key add '/tmp/repokey.gpg'
RUN echo "LC_ALL=en_US.UTF-8" >>/etc/environment
RUN locale-gen en_US.UTF-8

RUN echo "uxp-proxy uxp-common/username string uxpadmin" | debconf-set-selections
RUN useradd -m uxpadmin -s /usr/sbin/nologin -p '$6$7rx.CcTn$lkhsqW3zu6BrKbnQbOMaIFsZWv.DgH5LxtsXuxDftj8yF2e/KgxTOUQFozkYfcf1H.HSyxEtECMF8P7vy4M1b/'

RUN apt-get -qq update \
    && apt-get -y --no-install-recommends install ssl-cert \
    && apt-get -y --no-install-recommends install postgresql-10 postgresql-contrib --no-install-recommends \
    && apt-get -y --no-install-recommends install nginx \
    && apt-get clean  \
    && rm -rf /var/lib/apt/lists/*

RUN echo -e '#!/bin/sh\nexit 101' > /usr/sbin/policy-rc.d && chmod +x /usr/sbin/policy-rc.d
RUN echo -e '#!/bin/sh\nexit 0' > /usr/sbin/service && chmod +x /usr/sbin/service

RUN pg_ctlcluster 10 main start & \
    nginx & \
    sleep 5 && \
    apt-get -qq update \
    && apt-get -y --no-install-recommends install uxp-securityserver-ua  \
    && apt-get clean  \
    && rm -rf /var/lib/apt/lists/* \
    && wait

COPY ss_trembita.conf /etc/supervisor/supervisord.conf

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]

VOLUME ["/etc/uxp", "/var/lib/uxp", "/var/lib/postgresql/10/main/", "/var/log/uxp/"]
EXPOSE 4000 5500 5577 5599 443 80