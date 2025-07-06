FROM registry.access.redhat.com/ubi8/ubi:8.10

ARG MAVEN_VERSION=3.9.10
ARG SONAR_SCANNER_VERSION=5.0.1.3006
ARG GITHUB_RUNNER_VERSION=2.325.0

# Set environment variables
#ENV JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk \
#    MAVEN_HOME=/opt/maven \
#    PATH=$PATH:/opt/maven/bin:/usr/lib/jvm/java-1.8.0-openjdk/bin
ENV JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk \
    MAVEN_HOME=/opt/maven \
    SONAR_SCANNER_HOME=/opt/sonar-scanner \
    RUNNER_HOME=/home/runner/actions-runner \
    PATH=$PATH:/opt/maven/bin:/opt/sonar-scanner/bin:/usr/lib/jvm/java-1.8.0-openjdk/bin

# Install Java 8 and dependencies
#RUN dnf install -y \
#        java-1.8.0-openjdk-devel \
#        curl \
#        tar \
#        unzip \
#    && dnf clean all

RUN dnf install -y \
        curl \
        tar \
        unzip \
        git \
        libicu \
        krb5-libs \
        libcurl \
        openssl \
        zlib \
        gettext \
    && dnf clean all

# Install Maven
RUN curl -fsSL https://dlcdn.apache.org/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz -o /tmp/maven.tar.gz && \
    mkdir -p /opt && \
    tar -xzf /tmp/maven.tar.gz -C /opt && \
    ln -s /opt/apache-maven-${MAVEN_VERSION} /opt/maven && \
    rm -f /tmp/maven.tar.gz

# Install Sonar Scanner
RUN curl -fsSL https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-${SONAR_SCANNER_VERSION}-linux.zip -o /tmp/sonar.zip && \
    unzip /tmp/sonar.zip -d /opt && \
    ln -s /opt/sonar-scanner-${SONAR_SCANNER_VERSION}-linux /opt/sonar-scanner && \
    rm -f /tmp/sonar.zip


# Add runner user
RUN useradd -m runner

# Install GitHub Actions Runner
USER runner
WORKDIR /home/runner

RUN mkdir -p ${RUNNER_HOME} && \
    cd ${RUNNER_HOME} && \
    curl -fsSL -o actions-runner.tar.gz https://github.com/actions/runner/releases/download/v${GITHUB_RUNNER_VERSION}/actions-runner-linux-x64-${GITHUB_RUNNER_VERSION}.tar.gz && \
    tar -xzf actions-runner.tar.gz && \
    rm actions-runner.tar.gz

# Add entrypoint script
USER root
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

USER runner
ENTRYPOINT ["/entrypoint.sh"]
# Verify Java and Maven (optional)
#RUN java -version && mvn -version
# Verify Java, Maven and Sonar Scanner
#RUN java -version && \
#    mvn -version && \
#    sonar-scanner --version