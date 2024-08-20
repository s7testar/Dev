# Use Ubuntu 18.04 as the base image
FROM ubuntu:18.04
# Make sure the package repository is up to date and install necessary packages
RUN apt-get update && \
    apt-get install -qy \
    git \
    apt-utils \
    openssh-server \
    fontconfig \
    openjdk-17-jre \
    maven && \
    # Configure SSH
    sed -i 's|session    required     pam_loginuid.so|session    optional     pam_loginuid.so|g' /etc/pam.d/sshd && \
    mkdir -p /var/run/sshd && \
    # Cleanup old packages
    apt-get -qy autoremove && \
    # Add user jenkins to the image
    adduser --disabled-password --gecos "" jenkins && \
    # Set password for the jenkins user
    echo "jenkins:password" | chpasswd && \
    mkdir /home/jenkins/.m2 && \
    # Copy authorized keys
    mkdir -p /home/jenkins/.ssh && \
    chown -R jenkins:jenkins /home/jenkins && \
    chmod 700 /home/jenkins/.ssh && \
    chmod 600 /home/jenkins/.ssh/authorized_keys && \
    # Add Trivy GPG key
    wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | apt-key add - && \
    # Add Trivy repository to sources list
    echo "deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | tee /etc/apt/sources.list.d/trivy.list && \
    # Update package list
    apt-get update && \
    # Install Trivy
    apt-get install -y trivy && \
    # Cleanup apt cache
    apt-get clean

# Standard SSH port
EXPOSE 22

# Start SSH service
CMD ["/usr/sbin/sshd", "-D"]
