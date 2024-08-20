#!/bin/sh

# Run a series of commands inside the Vagrant VM

# Update package lists and upgrade packages
vagrant ssh Master -c "sudo apt-get update && sudo apt-get upgrade -y"

# Configure UFW firewall
vagrant ssh Master -c "sudo ufw allow 8080"
vagrant ssh Master -c "sudo ufw allow OpenSSH"
vagrant ssh Master -c "sudo ufw enable -y"
vagrant ssh Master -c "sudo ufw allow http"
vagrant ssh Master -c "sudo ufw allow https"

# Install Docker
vagrant ssh Master -c "sudo apt install docker.io -y && sudo systemctl enable docker && sudo systemctl start docker"

# Install Kubernetes
vagrant ssh Master -c "curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg"
vagrant ssh Master -c "echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list"
vagrant ssh Master -c "sudo apt update && sudo apt install -y kubeadm kubelet kubectl && sudo apt-mark hold kubeadm kubelet kubectl && kubeadm version"

# Disable swap and configure sysctl
vagrant ssh Master -c "sudo swapoff -a && sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab"
vagrant ssh Master -c "echo 'overlay' | sudo tee /etc/modules-load.d/containerd.conf"
vagrant ssh Master -c "echo 'br_netfilter' | sudo tee -a /etc/modules-load.d/containerd.conf"
vagrant ssh Master -c "sudo modprobe overlay && sudo modprobe br_netfilter"
vagrant ssh Master -c "echo 'net.bridge.bridge-nf-call-ip6tables = 1' | sudo tee /etc/sysctl.d/kubernetes.conf"
vagrant ssh Master -c "echo 'net.bridge.bridge-nf-call-iptables = 1' | sudo tee -a /etc/sysctl.d/kubernetes.conf"
vagrant ssh Master -c "echo 'net.ipv4.ip_forward = 1' | sudo tee -a /etc/sysctl.d/kubernetes.conf"
vagrant ssh Master -c "sudo sysctl --system"

# Set hostname & Update /etc/hosts
vagrant ssh Master -c "sudo hostnamectl set-hostname master-node"
vagrant ssh Master -c "echo '192.168.56.11 master-node' | sudo tee -a /etc/hosts"
vagrant ssh Master -c "echo '192.168.56.12 worker1-node' | sudo tee -a /etc/hosts"
vagrant ssh Master -c "echo '192.168.56.13 worker2-node' | sudo tee -a /etc/hosts"

#Initialize Kubernetes on Master Node
vagrant ssh Master -c 'echo "KUBELET_EXTRA_ARGS=\"--cgroup-driver=cgroupfs\"" | sudo tee -a /etc/default/kubelet'
vagrant ssh Master -c "sudo systemctl daemon-reload && sudo systemctl restart kubelet"
# Configure Docker to use systemd as the cgroup driver
vagrant ssh Master -c "echo '{
   \"exec-opts\": [\"native.cgroupdriver=systemd\"],
   \"log-driver\": \"json-file\",
   \"log-opts\": {
      \"max-size\": \"100m\"
   },
   \"storage-driver\": \"overlay2\"
}' | sudo tee /etc/docker/daemon.json"
vagrant ssh Master -c "sudo systemctl daemon-reload && sudo systemctl restart docker"

vagrant ssh Master -c "echo 'Environment=\"KUBELET_EXTRA_ARGS=--fail-swap-on=false\"' | sudo tee -a /lib/systemd/system/kubelet.service.d/10-kubeadm.conf"
vagrant ssh Master -c "sudo systemctl daemon-reload && sudo systemctl restart kubelet"

# Configure containerd to use the recommended CRI sandbox image
vagrant ssh Master -c "sudo mkdir -p /etc/containerd"
vagrant ssh Master -c "sudo containerd config default | sudo tee /etc/containerd/config.toml"
vagrant ssh Master -c "sudo sed -i 's|sandbox_image = \".*\"|sandbox_image = \"registry.k8s.io/pause:3.9\"|' /etc/containerd/config.toml"
vagrant ssh Master -c "sudo systemctl restart containerd"

# Initialize Kubernetes on Master Node
vagrant ssh Master -c "sudo kubeadm init --control-plane-endpoint=master-node --upload-certs"
vagrant ssh Master -c "mkdir -p \$HOME/.kube && sudo cp -i /etc/kubernetes/admin.conf \$HOME/.kube/config && sudo chown \$(id -u):\$(id -g) \$HOME/.kube/config"

# Deploy Pod Network (Calico)
vagrant ssh Master -c "kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.28.1/manifests/tigera-operator.yaml"
vagrant ssh Master -c "curl https://raw.githubusercontent.com/projectcalico/calico/v3.28.1/manifests/custom-resources.yaml -O"
vagrant ssh Master -c "kubectl create -f custom-resources.yaml"
vagrant ssh Master -c "curl https://raw.githubusercontent.com/projectcalico/calico/v3.28.1/manifests/calico.yaml -O"
vagrant ssh Master -c "kubectl apply -f calico.yaml"

# Remove control-plane taints to allow scheduling pods on the master node
vagrant ssh Master -c "kubectl taint nodes --all node-role.kubernetes.io/control-plane-"

# Install Java
vagrant ssh Master -c "sudo apt update && sudo apt install fontconfig openjdk-17-jre && java -version"

# Install Jenkins
vagrant ssh Master -c "sudo wget -O /usr/share/keyrings/jenkins-keyring.asc https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key"
vagrant ssh Master -c "echo 'deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/' | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null"
vagrant ssh Master -c "sudo apt-get update && sudo apt-get install jenkins -y && sudo systemctl enable jenkins && sudo systemctl start jenkins"
vagrant ssh Master -c "sudo usermod -aG docker jenkins"
vagrant ssh Master -c "sudo systemctl restart jenkins"

# Install Helm
vagrant ssh Master -c "sudo snap install helm --classic && helm repo add bitnami https://charts.bitnami.com/bitnami"

# Install Argo CD
vagrant ssh Master -c "kubectl create namespace argocd && kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml"
vagrant ssh Master -c "kubectl patch svc argocd-server -n argocd -p '{\"spec\": {\"type\": \"NodePort\"}}'"

# Install Terraform
vagrant ssh Master -c "sudo apt-get update && sudo apt-get install -y gnupg software-properties-common"
vagrant ssh Master -c "wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null"
vagrant ssh Master -c "gpg --no-default-keyring --keyring /usr/share/keyrings/hashicorp-archive-keyring.gpg --fingerprint"
vagrant ssh Master -c "echo 'deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main' | sudo tee /etc/apt/sources.list.d/hashicorp.list"
vagrant ssh Master -c "sudo apt update && sudo apt-get install -y terraform"
vagrant ssh Master -c "touch ~/.bashrc && terraform -install-autocomplete"

#Install pip
vagrant ssh Master -c "curl -O https://bootstrap.pypa.io/get-pip.py"
vagrant ssh Master -c "python3 get-pip.py --user"
vagrant ssh Master -c "echo 'export PATH=\"\$HOME/.local/bin:\$PATH\"' >> ~/.bashrc"
vagrant ssh Master -c "source ~/.bashrc"
vagrant ssh Master -c "pip3 install awscli --upgrade --user"


# Install Ansible
vagrant ssh Master -c "sudo apt update && sudo apt install software-properties-common -y"
vagrant ssh Master -c "sudo add-apt-repository --yes --update ppa:ansible/ansible"
vagrant ssh Master -c "sudo apt install ansible -y"

# Install Packer
vagrant ssh Master -c "sudo apt-get update && sudo apt-get install -y gnupg software-properties-common"
vagrant ssh Master -c "curl -fsSL https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null"
vagrant ssh Master -c "echo 'deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main' | sudo tee /etc/apt/sources.list.d/hashicorp.list"
vagrant ssh Master -c "sudo apt-get update && sudo apt-get install -y packer"
vagrant ssh Master -c "sleep 60"

#installing sonarqube
vagrant ssh Master -c "sudo apt update && sudo apt upgrade -y"
# Automated repository configuration
vagrant ssh Master -c "sudo apt install -y postgresql-common"
vagrant ssh Master -c "sudo /usr/share/postgresql-common/pgdg/apt.postgresql.org.sh"
# Manually configure the Apt repository
vagrant ssh Master -c "sudo apt install curl ca-certificates"
vagrant ssh Master -c "sudo install -d /usr/share/postgresql-common/pgdg"
vagrant ssh Master -c "sudo curl -o /usr/share/postgresql-common/pgdg/apt.postgresql.org.asc --fail https://www.postgresql.org/media/keys/ACCC4CF8.asc"
# Create the repository configuration file
vagrant ssh Master -c "sudo sh -c 'echo \"deb [signed-by=/usr/share/postgresql-common/pgdg/apt.postgresql.org.asc] https://apt.postgresql.org/pub/repos/apt \$(lsb_release -cs)-pgdg main\" > /etc/apt/sources.list.d/pgdg.list'"
# Update the package lists
vagrant ssh Master -c "sudo apt update"
# Install the latest version of PostgreSQL
vagrant ssh Master -c "sudo apt -y install postgresql"
# Start and enable PostgreSQL
vagrant ssh Master -c "sudo systemctl start postgresql"
vagrant ssh Master -c "sudo systemctl enable postgresql"
# Change default password for the postgres user
vagrant ssh Master -c "sudo passwd postgres"
# Switch to postgres user
vagrant ssh Master -c "su - postgres -c 'createuser sonar'"
# Login to the PostgreSQL database dashboard
vagrant ssh Master -c "su - postgres -c 'psql'"
# Create password for sonar user, create DB, and assign privileges
vagrant ssh Master -c "su - postgres -c \"psql -c \\\"ALTER USER sonar WITH ENCRYPTED PASSWORD 'Kathmandu42@';\\\"\""
vagrant ssh Master -c "su - postgres -c \"psql -c \\\"CREATE DATABASE sonarqube OWNER sonar;\\\"\""
vagrant ssh Master -c "su - postgres -c \"psql -c \\\"GRANT ALL PRIVILEGES ON DATABASE sonarqube to sonar;\\\"\""
# Exit from postgres user
vagrant ssh Master -c "exit"
# Step 3: Install and Configure SonarQube
vagrant ssh Master -c "sudo apt update"
vagrant ssh Master -c "sudo apt install wget unzip -y"
vagrant ssh Master -c "cd /opt/ && sudo wget https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-10.6.0.92116.zip"
vagrant ssh Master -c "sudo unzip /opt/sonarqube-10.6.0.92116.zip -d /opt/"
vagrant ssh Master -c "sudo mv /opt/sonarqube-10.6.0.92116 /opt/sonarqube"
# Users & Groups
vagrant ssh Master -c "sudo groupadd sonar"
vagrant ssh Master -c "sudo useradd -c 'user to run SonarQube' -d /opt/sonarqube -g sonar sonar"
vagrant ssh Master -c "sudo chown -R sonar:sonar /opt/sonarqube"
vagrant ssh Master -c "sudo chown -R sonar:sonar /opt/sonarqube"
vagrant ssh Master -c "sudo systemctl daemon-reload"

# Configure SonarQube
vagrant ssh Master -c "sudo sed -i 's/#sonar.jdbc.username=/sonar.jdbc.username=sonar/' /opt/sonarqube/conf/sonar.properties"
vagrant ssh Master -c "sudo sed -i 's/#sonar.jdbc.password=/sonar.jdbc.password=Kathmandu42@/' /opt/sonarqube/conf/sonar.properties"
vagrant ssh Master -c "sudo sed -i 's/#RUN_AS_USER=/RUN_AS_USER=sonar/' /opt/sonarqube/bin/linux-x86-64/sonar.sh"
# Setup Systemd Service
vagrant ssh Master -c "sudo bash -c 'cat > /etc/systemd/system/sonar.service' <<EOF
[Unit]
Description=SonarQube service
After=syslog.target network.target

[Service]
Type=forking

ExecStart=/opt/sonarqube/bin/linux-x86-64/sonar.sh start
ExecStop=/opt/sonarqube/bin/linux-x86-64/sonar.sh stop

User=sonar
Group=sonar
Restart=always

LimitNOFILE=65536
LimitNPROC=4096

[Install]
WantedBy=multi-user.target
EOF"
# Reload systemd, enable and start SonarQube service
vagrant ssh Master -c "sudo systemctl daemon-reload"
vagrant ssh Master -c "sudo systemctl start sonar"
vagrant ssh Master -c "sudo systemctl enable sonar"
# Modify Kernel System Limits
vagrant ssh Master -c "sudo sysctl -w vm.max_map_count=524288"
vagrant ssh Master -c "sudo sysctl -w fs.file-max=131072"
vagrant ssh Master -c "ulimit -n 131072"
vagrant ssh Master -c "ulimit -u 8192"

vagrant ssh Master -c "SONAR_JAVA_OPTS='-Xms256m -Xmx512m -XX:MaxPermSize=512m'"
vagrant ssh Master -c "sudo fallocate -l 4G /swapfile"
vagrant ssh Master -c "sudo chmod 600 /swapfile"
vagrant ssh Master -c "sudo mkswap /swapfile"
vagrant ssh Master -c "sudo swapon /swapfile"
vagrant ssh Master -c "echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab"

# Reload systemd, enable and start SonarQube service
vagrant ssh Master -c "sudo systemctl daemon-reload"
vagrant ssh Master -c "sudo systemctl start sonar"
vagrant ssh Master -c "sudo systemctl enable sonar"

# Display versions
vagrant ssh Master -c "echo 'The version of ansible is:' && ansible --version"
vagrant ssh Master -c "echo 'The version of terraform is:' && terraform --version"
vagrant ssh Master -c "echo 'The version of packer is:' && packer --version"

# Check pod status
vagrant ssh Master -c "kubectl get pods --all-namespaces"

# Getting credentials
vagrant ssh Master -c "echo 'jenkins password is:' && sudo cat /var/lib/jenkins/secrets/initialAdminPassword"
vagrant ssh Master -c "echo 'Argo CD password is:' && kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
vagrant ssh Master -c "kubectl get svc -n argocd"
vagrant ssh Master -c "kubectl get node -o wide"
#paste here 



#vagrant ssh Master -c "git config --list"
vagrant ssh Master 

#installing trivy
vagrant ssh Master -c "sudo apt-get install wget apt-transport-https gnupg"
vagrant ssh Master -c "wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | gpg --dearmor | sudo tee /usr/share/keyrings/trivy.gpg > /dev/null"
Vagrant ssh Master -c "echo 'deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb generic main' | sudo tee -a /etc/apt/sources.list.d/trivy.list"
vagrant ssh Master -c "sudo apt-get update"
vagrant ssh Master -c "sudo apt-get install trivy"

#using RBAC to deploy application into kubernetes for the maven project 
vagrant ssh Master -c "kubectl create ns maven"
vagrant ssh Master -c "kubectl apply -f roles.yml"
vagrant ssh Master -c "kubectl apply -f service.account.yml"
vagrant ssh Master -c "kubectl apply -f bindservicerole.yml"
vagrant shh Master -c "kubectl apply -f secret.yml" 
vagrant ssh Master -c "kubectl describe secret mysecret -n maven"





