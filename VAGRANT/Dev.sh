#!/bin/sh

# Update package lists and upgrade packages
vagrant ssh Dev -c "sudo apt-get update && sudo apt-get upgrade -y"

# Configure UFW firewall
vagrant ssh Dev -c "sudo ufw allow 4243/tcp"
vagrant ssh Dev -c "sudo ufw allow 32768:60999/tcp"
vagrant ssh Dev -c "sudo ufw allow OpenSSH"
vagrant ssh Dev -c "echo 'y' | sudo ufw enable"   # Automatically answer "yes" to enable UFW
vagrant ssh Dev -c "sudo ufw allow http"
vagrant ssh Dev -c "sudo ufw allow https"

# Install Docker
vagrant ssh Dev -c "sudo apt install docker.io -y && sudo systemctl enable docker && sudo systemctl start docker"

# Configure Docker Host with Remote API
vagrant ssh Dev -c "sudo sed -i 's|^\(ExecStart=.*\)|#\1|' /lib/systemd/system/docker.service"
vagrant ssh Dev -c "sudo sed -i '/^#ExecStart=/a ExecStart=/usr/bin/dockerd -H tcp://0.0.0.0:4243 -H unix:///var/run/docker.sock' /lib/systemd/system/docker.service"
vagrant ssh Dev -c "sudo systemctl daemon-reload"
vagrant ssh Dev -c "sudo systemctl restart docker"

# Validate API by executing curl command
vagrant ssh Dev -c "curl -s http://localhost:4243/version" # Use -s for silent mode to avoid progress output

# Build Jenkins slave Docker image
vagrant ssh Dev -c "git clone https://github.com/akannan1087/jenkins-docker-slave"
vagrant ssh Dev -c "mv /home/vagrant/jenkins-docker-slave/* /home/vagrant/ && rm -rf /home/vagrant/jenkins-docker-slave"
# Define paths
SOURCE_PATH="/home/vagrant/Downloads/Dockerfile"
DESTINATION_PATH="/home/vagrant/Dockerfile"
# Replace the Dockerfile
vagrant ssh Dev -c "cp $SOURCE_PATH $DESTINATION_PATH"
# Verify the replacement
vagrant ssh Dev -c "ls -l $DESTINATION_PATH"
#vagrant ssh Dev -c "sudo sed -i 's/ubuntu:18.04/ubuntu:22.04/' Dockerfile"
vagrant ssh Dev -c "sudo docker build -t my-jenkins-slave ."
#vagrant ssh Dev -c "sudo docker build -t docker-image /home/vagrant/Downloads/Dockerfile1
# Install SonarQube Scanner
# Download, unzip, and set up SonarQube Scanner on the vm that will hold your project 
vagrant ssh Dev -c "wget https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-6.1.0.4477-linux-x64.zip && unzip sonar-scanner-cli-6.1.0.4477-linux-x64.zip"
vagrant ssh Dev -c "sudo mv sonar-scanner-6.1.0.4477-linux-x64 /opt/sonar-scanner"
vagrant ssh Dev -c "sudo ln -s /opt/sonar-scanner/bin/sonar-scanner /usr/local/bin/sonar-scanner"
#vagrant ssh Dev -c "echo 'export PATH="/opt/sonar-scanner/bin:$PATH"' >> ~/.bashrc source ~/.bashrc" 
vagrant ssh Dev -c "echo 'export PATH=\"/opt/sonar-scanner/bin:\$PATH\"' >> ~/.bashrc && source ~/.bashrc"
#Download Nexus
vagrant ssh Dev -c "sudo apt-get update && sudo apt-get upgrade -y"
vagrant ssh Dev -c "sudo sudo apt install docker-compose -y"
vagrant ssh Dev -c "sudo usermod -aG docker vagrant"
vagrant ssh Dev -c "cp /home/vagrant/Downloads/Dockerfile1 /home/vagrant/docker-compose.yaml"
vagrant ssh Dev -c "sudo docker-compose up -d" 
vagrant ssh Dev -c "sleep 120 && sudo docker exec -it vagrant_nexus_1 cat /nexus-data/admin.password"
vagrant ssh Dev -c "exit"
# List Docker images to verify build
vagrant ssh Dev -c "sudo docker images && sudo docker ps"
vagrant ssh Dev 





