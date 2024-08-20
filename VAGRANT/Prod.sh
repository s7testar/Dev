#!/bin/sh

# Update package lists and upgrade packages
vagrant ssh Dev -c "sudo apt-get update && sudo apt-get upgrade -y"

# Configure UFW firewall
vagrant ssh Prod -c "sudo ufw allow 4243/tcp"
vagrant ssh Prod -c "sudo ufw allow 32768:60999/tcp"
vagrant ssh Prod -c "sudo ufw allow OpenSSH"
vagrant ssh Prod -c "echo 'y' | sudo ufw enable"   # Automatically answer "yes" to enable UFW
vagrant ssh Prod -c "sudo ufw allow http"
vagrant ssh Prod -c "sudo ufw allow https"

# Install Docker
vagrant ssh Prod -c "sudo apt-get update --fix-missing"
vagrant ssh Prod -c "sudo apt install docker.io -y && sudo systemctl enable docker && sudo systemctl start docker"

# Configure Docker Host with Remote API
vagrant ssh Prod -c "sudo sed -i 's|^\(ExecStart=.*\)|#\1|' /lib/systemd/system/docker.service"
vagrant ssh Prod -c "sudo sed -i '/^#ExecStart=/a ExecStart=/usr/bin/dockerd -H tcp://0.0.0.0:4243 -H unix:///var/run/docker.sock' /lib/systemd/system/docker.service"
vagrant ssh Prod -c "sudo systemctl daemon-reload"
vagrant ssh Prod -c "sudo systemctl restart docker"

# Validate API by executing curl command
vagrant ssh Prod -c "curl -s http://localhost:4243/version" # Use -s for silent mode to avoid progress output

# Build Jenkins slave Docker image
vagrant ssh Prod -c "git clone https://github.com/akannan1087/jenkins-docker-slave"
vagrant ssh Prod -c "mv /home/vagrant/jenkins-docker-slave/* /home/vagrant/ && rm -rf /home/vagrant/jenkins-docker-slave"
# Define paths
SOURCE_PATH="/home/vagrant/Downloads/Dockerfile"
DESTINATION_PATH="/home/vagrant/Dockerfile"
# Replace the Dockerfile
vagrant ssh Prod -c "cp $SOURCE_PATH $DESTINATION_PATH"
# Verify the replacement
vagrant ssh Prod -c "ls -l $DESTINATION_PATH"
#vagrant ssh Prod -c "sudo sed -i 's/ubuntu:18.04/ubuntu:22.04/' Dockerfile"
vagrant ssh Prod -c "sudo docker build -t my-jenkins-slave ."
# List Docker images to verify build
vagrant ssh Prod -c "sudo docker images"
vagrant ssh Prod 
























<< 'EOF'
echo "adding user"
sudo useradd -r -md /var/jenkins_home -s /bin/bash jenkins
cat /etc/passwd
ls -l /var/
sudo chown jenkins:jenkins -R /var/jenkins_home
sudo mkdir -p /usr/local/jenkins-service 
curl -sO http://192.168.56.11:8080/jnlpJars/agent.jar
cd ~
#sudo mv agent.jar /usr/local/jenkins-service/
sudo chown jenkins:jenkins -R /usr/local/jenkins-service

# create a script call start-agent in the service folder to start the agent

script='#!/bin/sh
cd /usr/local/jenkins-service
curl -sO http://192.168.56.11:8080/jnlpJars/agent.jar
java -jar agent.jar -url http://192.168.56.11:8080/ -secret 687d51226787504b7b415fa7da36936742390fa101a5165a0045256049337c42 -name agent1 -workDir "/var/jenkins_home"
exit 0'
# Write the content to the start-agent.sh file
echo "$script" | sudo tee /usr/local/jenkins-service/start-agent.sh

# Make the script executable
sudo chmod +x /usr/local/jenkins-service/start-agent.sh

# Define the service file content
SERVICE_CONTENT="[Unit]
Description=Jenkins Agent

[Service]
User=jenkins
WorkingDirectory=/var/jenkins_home
ExecStart=/bin/bash /usr/local/jenkins-service/start-agent.sh
Restart=always

[Install]
WantedBy=multi-user.target"

# Write the content to the service file
echo "$SERVICE_CONTENT" | sudo tee /etc/systemd/system/jenkins-agent.service

# Reload the systemd daemon to recognize the new service
sudo systemctl daemon-reload

# Enable the service to start on boot
sudo systemctl enable jenkins-agent.service

# Start the service immediately
sudo systemctl start jenkins-agent.service

EOF








