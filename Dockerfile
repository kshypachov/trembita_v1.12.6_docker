FROM ubuntu:18.04 AS base
ENV DEBIAN_FRONTEND=noninteractive

LABEL authors="Kirill Shypachov @kshypachov"
ARG REPO_KEY=https://project-repo.trembita.gov.ua:8081/public-keys/public.key.txt

RUN apt-get -qq update \
    && apt-get -qq install gnupg2 \
    && apt-get -qq --no-install-recommends install \
      locales ca-certificates perl bzip2 libc6-dev lsb-release \
      ca-certificates gnupg supervisor net-tools iproute2 locales \
      rlwrap ca-certificates-java \
      crudini adduser expect curl rsyslog dpkg-dev \
    && adduser --quiet --system --uid 998 --home /var/lib/postgresql --no-create-home --shell /bin/bash --group postgres \
    && adduser --quiet --system --uid 999 --home /var/lib/uxp --no-create-home --shell /bin/bash --group uxp \
    && useradd -m uxpadmin -s /usr/sbin/nologin -p '$6$7rx.CcTn$lkhsqW3zu6BrKbnQbOMaIFsZWv.DgH5LxtsXuxDftj8yF2e/KgxTOUQFozkYfcf1H.HSyxEtECMF8P7vy4M1b/' \
    && echo "uxp-proxy uxp-common/username string uxpadmin" | debconf-set-selections \
    && echo "LC_ALL=en_US.UTF-8" >>/etc/environment \
    && locale-gen en_US.UTF-8 \
    && apt-get clean  \
    && rm -rf /var/lib/apt/lists/*

RUN sed -i 's/^[A-Za-z0-9]/#&/' /etc/apt/sources.list
RUN echo "deb https://project-repo.trembita.gov.ua:8081/repository/ss-1.12.6/ bionic main" | tee -a /etc/apt/sources.list
RUN echo "deb https://project-repo.trembita.gov.ua:8081/repository/trembita-member_archive/ certified main" | tee -a /etc/apt/sources.list

ADD ["$REPO_KEY","/tmp/repokey.gpg"]
RUN apt-key add '/tmp/repokey.gpg'

RUN apt-get -qq update \
    && apt-get -qq -y --no-install-recommends install ssl-cert postgresql-10 postgresql-contrib nginx \
    && apt-get clean  \
    && rm -rf /var/lib/apt/lists/*

RUN printf '#!/bin/sh\nexit 101\n' > /usr/sbin/policy-rc.d && chmod +x /usr/sbin/policy-rc.d \
    && printf '#!/bin/sh\nexit 0\n' > /usr/sbin/service && chmod +x /usr/sbin/service

RUN pg_ctlcluster 10 main start \
    && apt-get -qq update \
    && apt-get -qq -y --no-install-recommends install uxp-securityserver-ua  \
    && pg_ctlcluster 10 main stop  \
    && apt-get clean  \
    && rm -rf /var/lib/apt/lists/* \
    && wait

COPY ss_trembita.conf /etc/supervisor/supervisord.conf
COPY entrypoint.sh /root/entrypoint.sh
COPY nginx_default-uxp.conf /etc/nginx/sites-enabled/default-uxp

RUN chown -R uxp:uxp /etc/uxp /var/lib/uxp /var/log/uxp /usr/share/uxp/jlib \
    && chown -R postgres:postgres /var/lib/postgresql/ \
    && chmod 600 /etc/supervisor/supervisord.conf \
    && chmod +x /root/entrypoint.sh \
    && chmod 600 /etc/nginx/sites-enabled/default-uxp

CMD ["/root/entrypoint.sh"]

VOLUME ["/etc/uxp", "/var/lib/uxp", "/var/lib/postgresql/10/main/", "/var/log/uxp/"]
EXPOSE 4000 5500 5577 5599 443 80