FROM debian:jessie

RUN apt-get update \
    && apt-get install --yes --no-install-recommends \
       wget \
       ca-certificates \
       unzip \
       supervisor \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*


# Install Yelp's dumb-init for proper top-level process management.
ENV DUMB_INIT_VERSION 1.0.1
ENV DUMB_INIT_SHA256 91b9970e6a0d23d7aedf3321fb1d161937e7f5e6ff38c51a8a997278cc00fb0a

RUN wget https://github.com/Yelp/dumb-init/releases/download/v${DUMB_INIT_VERSION}/dumb-init_${DUMB_INIT_VERSION}_amd64 -O /usr/local/bin/dumb-init \
    && echo "${DUMB_INIT_SHA256} /usr/local/bin/dumb-init" | sha256sum -c - \
    && chmod +x /usr/local/bin/dumb-init

# Grab gosu for easy step-down from root
ENV GOSU_VERSION 1.7
RUN set -x \
	&& wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture)" \
	&& wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture).asc" \
	&& export GNUPGHOME="$(mktemp -d)" \
	&& gpg --keyserver ha.pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
	&& gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu \
	&& rm -r "$GNUPGHOME" /usr/local/bin/gosu.asc \
	&& chmod +x /usr/local/bin/gosu \
	&& gosu nobody true

ENV CONSUL_TEMPLATE_VERSION 0.14.0
ENV CONSUL_TEMPLATE_SHA256 7c70ea5f230a70c809333e75fdcff2f6f1e838f29cfb872e1420a63cdf7f3a78

RUN wget --quiet https://releases.hashicorp.com/consul-template/${CONSUL_TEMPLATE_VERSION}/consul-template_${CONSUL_TEMPLATE_VERSION}_linux_amd64.zip -O /consul-template.zip \
    && echo "${CONSUL_TEMPLATE_SHA256} /consul-template.zip" | sha256sum -c - \
    && unzip /consul-template.zip -d /usr/local/bin \
    && rm -rf /consul-template.zip

RUN mkdir -p /config/supervisord /config/consul-template /supervisor/run /supervisor/log /supervisor/log/services

VOLUME /supervisor

ADD supervisord.conf /etc/supervisor/supervisord.conf
ADD consul-template.cfg /config/consul-template/000-consul-template.cfg
ADD stop-supervisord.py /supervisor/stop-supervisord.py

CMD [ \
    "dumb-init", \
    "/usr/bin/supervisord", \
    "--configuration", "/etc/supervisor/supervisord.conf" \
]
