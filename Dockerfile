FROM java:8u45-jdk

RUN apt-get update && apt-get install -y wget git curl zip && rm -rf /var/lib/apt/lists/*

ENV HUDSON /var/hudson_home

# HUDSON is ran with user `hudson`, uid = 1000
# If you bind mount a volume from host/vloume from a data container, 
# ensure you use same uid
RUN useradd -d "$HUDSON" -u 1000 -m -s /bin/bash hudson

# hudson home directoy is a volume, so configuration and build history 
# can be persisted and survive image upgrades
VOLUME /var/hudson_home

# `/usr/share/hudson/ref/` contains all reference configuration we want 
# to set on a fresh new installation. Use it to bundle additional plugins 
# or config file with your custom hudson Docker image.
RUN mkdir -p /usr/share/hudson/ref/init.groovy.d

# Use tini as subreaper in Docker container to adopt zombie processes 
RUN curl -fL https://github.com/krallin/tini/releases/download/v0.5.0/tini-static -o /bin/tini && chmod +x /bin/tini

COPY init.groovy /usr/share/hudson/ref/init.groovy.d/tcp-slave-agent-port.groovy

ENV HUDSON_VERSION 3.2.2


# could use ADD but this one does not check Last-Modified header 
# see https://github.com/docker/docker/issues/8331
RUN curl -fL http://hudson-ci.org/downloads/war/hudson-3.2.2.war -o /usr/share/hudson/hudson.war 

ENV HUDSON_UC https://updates.jenkins-ci.org
RUN chown -R hudson "$HUDSON" /usr/share/hudson/ref

# for main web interface:
EXPOSE 8080

# will be used by attached slave agents:
EXPOSE 50000

ENV COPY_REFERENCE_FILE_LOG $HUDSON/copy_reference_file.log

USER hudson

COPY hudson.sh /usr/local/bin/hudson.sh
ENTRYPOINT ["/bin/tini", "--", "/usr/local/bin/hudson.sh"]



