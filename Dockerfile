FROM debian:jessie

ARG rundeck_url="http://dl.bintray.com/rundeck/rundeck-deb/rundeck-2.7.1-1-GA.deb"
ARG rundeck_sha256sum="57986749f7496cf201cb89ebd44fe0859d86062f0783d9e653344d4894ba0559"
ARG rundeck_cli_url="https://github.com/rundeck/rundeck-cli/releases/download/v1.0.0-alpha/rundeck-cli_1.0.0.SNAPSHOT-1_all.deb"
ARG rundeck_cli_sha256sum="890ae85e0acdf703fa336bfc73a7129ce618794833d5744ddae901a1b2e38074"
ARG rundeck_ansible_plugin_url="https://github.com/Batix/rundeck-ansible-plugin/releases/download/2.0.2/ansible-plugin-2.0.2.jar"

ENV DEBIAN_FRONTEND noninteractive
ENV SERVER_URL https://localhost:4443
ENV RUNDECK_STORAGE_PROVIDER file
ENV RUNDECK_PROJECT_STORAGE_TYPE file
ENV NO_LOCAL_MYSQL false

RUN echo "deb http://ftp.debian.org/debian jessie-backports main" >> /etc/apt/sources.list && \
    apt-get -qq update && \
    apt-get -qqy install --no-install-recommends \
        bash openjdk-8-jre-headless supervisor procps sudo \
        ca-certificates openssh-client mysql-server mysql-client \
        pwgen build-essential curl git \
        libffi-dev libssl-dev python-dev python-pip

RUN pip install --upgrade distribute && \
    pip install --upgrade cffi && \
    pip install --upgrade pyasn1 && \
    pip install cryptography && \
    pip install docker-py jinja2 markupsafe paramiko pyyaml ansible 

RUN cd /tmp/ && \
    curl -Lo /tmp/rundeck.deb ${rundeck_url} && \
    echo "${rundeck_sha256sum}  rundeck.deb" > /tmp/rundeck.sig && \
    shasum -a256 -c /tmp/rundeck.sig && \
    curl -Lo /tmp/rundeck-cli.deb ${rundeck_cli_url} && \
    echo "${rundeck_cli_sha256sum}  rundeck-cli.deb" > /tmp/rundeck-cli.sig && \
    shasum -a256 -c /tmp/rundeck-cli.sig && \
    cd - && \
    dpkg -i /tmp/rundeck*.deb && rm /tmp/rundeck*.deb && \
    apt-get clean && rm -rf /var/lib/apt/lists

RUN mkdir -p /var/lib/rundeck/libext && \
    curl -Lo /var/lib/rundeck/libext/ansible-plugin.jar ${rundeck_ansible_plugin_url}

RUN chown rundeck:rundeck /tmp/rundeck && \
    mkdir -p /var/lib/rundeck/.ssh && \
    chown rundeck:rundeck /var/lib/rundeck/.ssh && \
    sed -i "s/export RDECK_JVM=\"/export RDECK_JVM=\"\${RDECK_JVM} /" /etc/rundeck/profile
 
ADD content/ /
RUN chmod u+x /opt/run && \
    mkdir -p /var/log/supervisor && mkdir -p /opt/supervisor && \
    chmod u+x /opt/supervisor/rundeck && chmod u+x /opt/supervisor/mysql_supervisor

EXPOSE 4440 4443

VOLUME  ["/etc/rundeck", "/var/rundeck", "/var/lib/rundeck", "/var/lib/mysql", "/var/log/rundeck", "/opt/rundeck-plugins", "/var/lib/rundeck/logs", "/var/lib/rundeck/var/storage"]

ENTRYPOINT ["/opt/run"]
