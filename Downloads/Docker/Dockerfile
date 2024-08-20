FROM docker:23.0.1-dind

RUN apk add --no-cache \
    git \
    openjdk17 \
    maven \
    curl \
    bash \
    openssh-client

# Add the Docker group and the Jenkins user to it
RUN addgroup -S docker && adduser -S jenkins -G docker

# Ensure Jenkins can access the Docker daemon
RUN mkdir -p /home/jenkins/.ssh && chown -R jenkins:docker /home/jenkins

USER jenkins


