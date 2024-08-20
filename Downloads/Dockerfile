
# Use Ubuntu 22.04 as the base image
FROM ubuntu:22.04

# Install necessary dependencies and Docker
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    openssh-server \
    sudo \
    git  \
    apt-utils \
    fontconfig \
    openjdk-17-jre \
    maven \
    wget \
    unzip \
    && curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list \
    && apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y docker-ce docker-ce-cli containerd.io \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Configure SSH
RUN mkdir -p /run/sshd && \
    echo 'root:root' | chpasswd && \
    sed -i 's|session    required     pam_loginuid.so|session    optional     pam_loginuid.so|g' /etc/pam.d/sshd && \
    echo "PermitRootLogin yes" >> /etc/ssh/sshd_config && \
    echo "UsePAM yes" >> /etc/ssh/sshd_config

# Create a user 'jenkins' with password 'jenkins' and add to 'docker' group
RUN useradd -m -s /bin/bash jenkins && echo "jenkins:jenkins" | chpasswd && usermod -aG docker jenkins

# Add Trivy GPG key and repository, then install Trivy
RUN wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | gpg --dearmor -o /usr/share/keyrings/trivy-archive-keyring.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/trivy-archive-keyring.gpg] https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" > /etc/apt/sources.list.d/trivy.list && \
    apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y trivy && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Expose SSH port
EXPOSE 22

# Start SSH and Docker services
CMD service docker start && /usr/sbin/sshd -D




