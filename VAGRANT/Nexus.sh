#!/bin/sh

# Update package lists and upgrade packages
vagrant ssh Nexus -c "sudo apt-get update && sudo apt-get upgrade -y"

# Configure UFW firewall
vagrant ssh Nexus -c "sudo ufw allow 4243/tcp"
vagrant ssh Nexus -c "sudo ufw allow 32768:60999/tcp"
vagrant ssh Nexus -c "sudo ufw allow OpenSSH"
vagrant ssh Nexus -c "echo 'y' | sudo ufw enable"   # Automatically answer "yes" to enable UFW
vagrant ssh Nexus -c "sudo ufw allow http"
vagrant ssh Nexus -c "sudo ufw allow https"

# Install Docker
vagrant ssh Nexus -c "sudo apt-get update --fix-missing"
vagrant ssh Nexus -c "sudo apt install docker.io -y && sudo systemctl enable docker && sudo systemctl start docker"

# Configure Docker Host with Remote API
vagrant ssh Nexus -c "sudo sed -i 's|^\(ExecStart=.*\)|#\1|' /lib/systemd/system/docker.service"
vagrant ssh Nexus -c "sudo sed -i '/^#ExecStart=/a ExecStart=/usr/bin/dockerd -H tcp://0.0.0.0:4243 -H unix:///var/run/docker.sock' /lib/systemd/system/docker.service"
vagrant ssh Nexus -c "sudo systemctl daemon-reload"
vagrant ssh Nexus -c "sudo systemctl restart docker"

# Validate API by executing curl command
vagrant ssh Nexus -c "curl -s http://localhost:4243/version" # Use -s for silent mode to avoid progress
vagrant ssh Nexus -c "sudo apt-get update && sudo apt-get upgrade -y"
vagrant ssh Nexus -c "sudo sudo apt install docker-compose -y"
vagrant ssh Nexus -c "sudo usermod -aG docker vagrant"
vagrant ssh Nexus -c "cp /home/vagrant/Downloads/Dockerfile1 /home/vagrant/docker-compose.yaml"
vagrant ssh Nexus -c "sudo docker-compose up -d" 
vagrant ssh Nexus -c "sleep 60 && sudo docker exec -it vagrant_nexus_1 cat /nexus-data/admin.password"
#output
vagrant ssh Nexus































<< 'EOF'

# Install Nexus
vagrant ssh Nexus -c "sudo docker volume create --name nexus-data"
vagrant ssh Nexus -c "docker pull sonatype/nexus3"  
vagrant ssh Nexus -c "sudo docker run -d -p 8081:8081 --name nexus -v nexus-data:/nexus-data sonatype/nexus3"
vagrant ssh Nexus -c "sleep 120"
vagrant ssh Nexus -c "sudo docker exec -t nexus /bin/bash -c 'cat sonatype-work/nexus3/admin.password && exit'"  
# List Docker images to verify build
vagrant ssh Nexus -c "sudo docker images && sudo docker ps"
vagrant ssh Nexus 




# Install Nexus
vagrant ssh Nexus -c "sudo docker volume create --name nexus-data"
vagrant ssh Nexus -c "sleep 45"
vagrant ssh Nexus -c "sudo docker run -d -p 8081:8081 --name nexus -v nexus-data:/nexus-data sonatype/nexus3"

# Wait for Nexus to fully initialize before fetching the admin password
vagrant ssh Nexus -c "sleep 30 && sudo docker exec -t nexus /bin/bash -c 'cat /nexus-data/sonatype-work/nexus3/admin.password'"

# List Docker images and running containers to verify build
vagrant ssh Nexus -c "sudo docker images && sudo docker ps"

EOF



















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





#!/bin/sh

# Update package lists and upgrade packages
vagrant ssh Nexus -c "sudo apt-get update && sudo apt-get upgrade -y"

# Configure UFW firewall
vagrant ssh Nexus -c "sudo ufw allow 4243/tcp"
vagrant ssh Nexus -c "sudo ufw allow 32768:60999/tcp"
vagrant ssh Nexus -c "sudo ufw allow OpenSSH"
vagrant ssh Nexus -c "echo 'y' | sudo ufw enable"   # Automatically answer "yes" to enable UFW
vagrant ssh Nexus -c "sudo ufw allow http"
vagrant ssh Nexus -c "sudo ufw allow https"

# Install Docker
vagrant ssh Nexus -c "sudo apt-get update --fix-missing"
vagrant ssh Nexus -c "sudo apt install docker.io -y && sudo systemctl enable docker && sudo systemctl start docker"

# Configure Docker Host with Remote API
vagrant ssh Nexus -c "sudo sed -i 's|^\(ExecStart=.*\)|#\1|' /lib/systemd/system/docker.service"
vagrant ssh Nexus -c "sudo sed -i '/^#ExecStart=/a ExecStart=/usr/bin/dockerd -H tcp://0.0.0.0:4243 -H unix:///var/run/docker.sock' /lib/systemd/system/docker.service"
vagrant ssh Nexus -c "sudo systemctl daemon-reload"
vagrant ssh Nexus -c "sudo systemctl restart docker"

# Validate API by executing curl command
vagrant ssh Nexus -c "curl -s http://localhost:4243/version" # Use -s for silent mode to avoid progress output
# Install Nexus
vagrant ssh Nexus -c "sudo docker volume create --name nexus-data && sudo docker run -d -p 8081:8081 --name nexus -v nexus-data:/nexus-data sonatype/nexus3"
vagrant ssh Nexus -c "sudo docker exec -t nexus /bin/bash -c 'cat sonatype-work/nexus3/admin.password && exit'"  
# List Docker images to verify build
vagrant ssh Nexus -c "sudo docker images && sudo docker ps"
vagrant ssh Nexus 







#!/bin/sh

# Update package lists and upgrade packages
vagrant ssh Nexus -c "sudo apt-get update && sudo apt-get upgrade -y"

# Configure UFW firewall
vagrant ssh Nexus -c "sudo ufw allow 4243/tcp"
vagrant ssh Nexus -c "sudo ufw allow 32768:60999/tcp"
vagrant ssh Nexus -c "sudo ufw allow OpenSSH"
vagrant ssh Nexus -c "echo 'y' | sudo ufw enable"   # Automatically answer "yes" to enable UFW
vagrant ssh Nexus -c "sudo ufw allow http"
vagrant ssh Nexus -c "sudo ufw allow https"

# Install Docker
vagrant ssh Nexus -c "sudo apt-get update --fix-missing"
vagrant ssh Nexus -c "sudo apt install docker.io -y && sudo systemctl enable docker && sudo systemctl start docker"

# Configure Docker Host with Remote API
vagrant ssh Nexus -c "sudo sed -i 's|^\(ExecStart=.*\)|#\1|' /lib/systemd/system/docker.service"
vagrant ssh Nexus -c "sudo sed -i '/^#ExecStart=/a ExecStart=/usr/bin/dockerd -H tcp://0.0.0.0:4243 -H unix:///var/run/docker.sock' /lib/systemd/system/docker.service"
vagrant ssh Nexus -c "sudo systemctl daemon-reload"
vagrant ssh Nexus -c "sudo systemctl restart docker"

# Validate API by executing curl command
vagrant ssh Nexus -c "curl -s http://localhost:4243/version" # Use -s for silent mode to avoid progress output

vagrant ssh Nexus -c "cp /home/vagrant/Downloads/Dockerfile1 /home/vagrant/Dockerfile"
vagrant ssh Nexus -c "sudo docker build -t nexus ."
vagrant ssh Nexus -c "sudo docker run -d -p 8081:8081 --name nexus nexus"
vagrant ssh Nexus -c "sleep 60 && sudo docker exec -t nexus /bin/bash -c 'cat /nexus-data/sonatype-work/nexus3/admin.password'"
vagrant ssh Nexus 

# Copy Dockerfile
vagrant ssh Nexus -c "cp /home/vagrant/Downloads/Dockerfile1 /home/vagrant/Dockerfile"




# Wait for Nexus to initialize and then retrieve the admin password
vagrant ssh Nexus -c "sleep 60 && sudo docker exec -t nexus /bin/bash -c 'cat /nexus-data/sonatype-work/nexus3/admin.password'"
EOF








