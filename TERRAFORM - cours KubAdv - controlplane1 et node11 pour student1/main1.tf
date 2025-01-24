# Configuration du provider AWS
provider "aws" {
  region = "eu-central-1"  
}

#####################################################################
# Création de l'instance controlplane1 EC2 t3.medium avec OS ubuntu #
#####################################################################
resource "aws_instance" "controlplane1" {
  ami                    = "ami-03b3b5f65db7e5c6f"  # AMI Ubuntu 22.04 LTS pour eu-central-1
  instance_type          = "t3.medium"
  subnet_id              = "subnet-070786d49edf2e769"
  vpc_security_group_ids = ["sg-0c570579ef91de3ad"]
  iam_instance_profile   = "kubeadv-role"
  
  user_data = <<-EOF
#!/bin/bash

# Configuration pour éviter les interactions lors de l'upgrade qui va suivre
echo "\$nrconf{restart} = 'a';" | sudo tee -a /etc/needrestart/needrestart.conf
echo 'DPkg::options { "--force-confdef"; "--force-confold"; }' | sudo tee /etc/apt/apt.conf.d/local
export DEBIAN_FRONTEND=noninteractive

# Mettre à jour le système
sudo apt-get update
sudo apt-get upgrade -y

# Installer AWS CLI
sudo apt-get install -y awscli

# Désactiver le swap
swapoff -a
sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# Configuration réseau Kubernetes
echo "br_netfilter" >> /etc/modules-load.d/k8s.conf
modprobe br_netfilter
echo "net.bridge.bridge-nf-call-iptables = 1" >> /etc/sysctl.d/k8s.conf
echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.d/k8s.conf
sysctl --system

# Installer kubeadm, kubelet et kubectl
sudo apt-get install -y apt-transport-https ca-certificates curl bash-completion

# Installation explicite du paquet bash-completion
sudo apt install -y bash-completion

# Configuration containerd
sudo apt update
sudo apt install -y containerd
mkdir -p /etc/containerd
containerd config default | sed 's/SystemdCgroup = false/SystemdCgroup = true/' > /etc/containerd/config.toml
systemctl restart containerd

# Ajouter le dépôt Kubernetes
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

sudo apt-get update
# Mettre toutes les versions 1.31 disponibles dans ce fichier de logs
apt-cache madison kubeadm >> /var/log/kubernetes_versions.log 2>&1

# Installer les paquets Kubernetes nécessaires
sudo apt-mark unhold kubelet kubeadm kubectl
sudo apt-get install -y kubelet=1.31.5-1.1 kubeadm=1.31.5-1.1 kubectl=1.31.5-1.1
sudo apt-mark hold kubelet kubeadm kubectl

# Initialiser le cluster Kubernetes (optionnel)
if ! sudo kubeadm init --pod-network-cidr=10.244.0.0/16 --node-name=controlplane1; then
    echo "Échec de l'initialisation du cluster Kubernetes"
    exit 1
fi

# Configurer le répertoire .kube pour root
mkdir -p /root/.kube
sudo cp -i /etc/kubernetes/admin.conf /root/.kube/config
chown root:root /root/.kube/config

# Configurer le répertoire .kube pour ssm-user
mkdir -p /home/ssm-user/.kube
sudo cp -i /etc/kubernetes/admin.conf /home/ssm-user/.kube/config

# Autocomplétion et alias kubectl pour root
echo 'source <(kubectl completion bash)' >> /root/.bashrc
echo 'alias k=kubectl' >> /root/.bashrc
echo 'complete -o default -F __start_kubectl k' >> /root/.bashrc

# Autocomplétion et alias kubectl pour ssm-user
echo 'source <(kubectl completion bash)' >> /home/ssm-user/.bashrc
echo 'alias k=kubectl' >> /home/ssm-user/.bashrc
echo 'complete -o default -F __start_kubectl k' >> /home/ssm-user/.bashrc

# Définir un nouveau nom d'hôte
hostnamectl set-hostname controlplane1

# Générer la clé publique à intégrer dans node11
ssh-keygen -t rsa -f /root/.ssh/id_rsa -N ""

# modifier la configuration sshd pour permettre l'accès SSH via RSA et autoriser l'accès Root
echo -e "PermitRootLogin yes\nPubkeyAuthentication yes\nAuthorizedKeysFile .ssh/authorized_keys" >> /etc/ssh/sshd_config
# après avoir configurer la pub_ssh_key sur controlplane1
systemctl restart sshd

# Attendre que le cluster soit complètement initialisé
until echo "Exécution de la commande : kubectl --kubeconfig=/etc/kubernetes/admin.conf get nodes"; kubectl --kubeconfig=/etc/kubernetes/admin.conf get nodes; do
    echo "En attente de la disponibilité du cluster..."
    sleep 10
done

# Installer Flannel sans validation
echo "Installation de Flannel : "
kubectl --kubeconfig=/etc/kubernetes/admin.conf apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml --validate=false

# Récupérer l'IP privée
private_ip=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)
# Stocker l'IP privée dans un fichier S3
echo "$private_ip" > /tmp/controlplane1-ip.txt
aws s3 cp /tmp/controlplane1-ip.txt s3://kubeadv786/controlplane1-ip.txt

# Récupérer la commande d'enregistrement pour le node11
node_registration=$(sudo kubeadm token create --print-join-command)
# Stocker la commande dans un fichier S3
echo "$node_registration" > /tmp/node11-registration.txt
aws s3 cp /tmp/node11-registration.txt s3://kubeadv786/node11-registration.txt

# Récupérer le fichier config k8s pour le node11
aws s3 cp /etc/kubernetes/admin.conf s3://kubeadv786/node11-config.txt

# Récupérer la clé publique pour l'accès SSH
authorized_keys01=$(cat /root/.ssh/id_rsa.pub)
# Stocker la clé publique dans un fichier S3
echo "$authorized_keys01" > /tmp/authorized_keys01.txt
aws s3 cp /tmp/authorized_keys01.txt s3://kubeadv786/authorized_keys01.txt

# Mettre à jour le fichier hosts avec l'IP du node11
cat > /root/node-to-ip << 'ENDSCRIPT'
#!/bin/bash
# Mettre à jour le fichier hosts pour node11
node11_ip=$(aws s3 cp s3://kubeadv786/node11-ip.txt - | tr -d '\r')
echo "$node11_ip node11" >> /etc/hosts
ENDSCRIPT
chmod +x /root/node-to-ip

  EOF

  user_data_replace_on_change = true

  root_block_device {
    volume_type = "gp3"
    volume_size = 20
  }

  tags = {
    Name = "controlplane1"
    user = "student1"
  }
}

##############################################################
# Création de l'instance EC2 node11 t3.medium avec OS ubuntu #
############################################################## 
resource "aws_instance" "node11" {
  ami                    = "ami-03b3b5f65db7e5c6f"  # AMI Ubuntu 22.04 LTS pour eu-central-1
  instance_type          = "t3.medium"
  subnet_id              = "subnet-070786d49edf2e769"
  vpc_security_group_ids = ["sg-0c570579ef91de3ad"]
  iam_instance_profile   = "kubeadv-role"
  
  user_data = <<-EOF
#!/bin/bash

# Configuration pour éviter les interactions lors de l'upgrade qui va suivre
echo "\$nrconf{restart} = 'a';" | sudo tee -a /etc/needrestart/needrestart.conf
echo 'DPkg::options { "--force-confdef"; "--force-confold"; }' | sudo tee /etc/apt/apt.conf.d/local
export DEBIAN_FRONTEND=noninteractive

# Mettre à jour le système
sudo apt-get update
sudo apt-get upgrade -y

# Installer AWS CLI
sudo apt-get install -y awscli

# Désactiver le swap
swapoff -a
sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# Configuration réseau Kubernetes
echo "br_netfilter" >> /etc/modules-load.d/k8s.conf
modprobe br_netfilter
echo "net.bridge.bridge-nf-call-iptables = 1" >> /etc/sysctl.d/k8s.conf
echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.d/k8s.conf
sysctl --system

# Installer kubeadm, kubelet et kubectl
sudo apt-get install -y apt-transport-https ca-certificates curl bash-completion

# Installation explicite du paquet bash-completion
sudo apt install -y bash-completion

# Configuration containerd
sudo apt update
sudo apt install -y containerd
mkdir -p /etc/containerd
containerd config default | sed 's/SystemdCgroup = false/SystemdCgroup = true/' > /etc/containerd/config.toml
systemctl restart containerd

# Ajouter le dépôt Kubernetes
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

sudo apt-get update
# Mettre toutes les versions 1.31 disponibles dans ce fichier de logs
apt-cache madison kubeadm >> /var/log/kubernetes_versions.log 2>&1

# Installer les paquets Kubernetes nécessaires
sudo apt-mark unhold kubelet kubeadm kubectl
sudo apt-get install -y kubelet=1.31.5-1.1 kubeadm=1.31.5-1.1 kubectl=1.31.5-1.1
sudo apt-mark hold kubelet kubeadm kubectl


# Créer les répertoires .kube
mkdir -p /root/.kube
mkdir -p /home/ssm-user/.kube

# Autocomplétion et alias kubectl pour root
echo 'source <(kubectl completion bash)' >> /root/.bashrc
echo 'alias k=kubectl' >> /root/.bashrc
echo 'complete -o default -F __start_kubectl k' >> /root/.bashrc

# Autocomplétion et alias kubectl pour ssm-user
echo 'source <(kubectl completion bash)' >> /home/ssm-user/.bashrc
echo 'alias k=kubectl' >> /home/ssm-user/.bashrc
echo 'complete -o default -F __start_kubectl k' >> /home/ssm-user/.bashrc

# Définir un nouveau nom d'hôte pour node11
hostnamectl set-hostname node11

# modifier la configuration sshd pour permettre l'accès SSH via RSA et autoriser l'accès Root
echo -e "PermitRootLogin yes\nPubkeyAuthentication yes\nAuthorizedKeysFile .ssh/authorized_keys" >> /etc/ssh/sshd_config
# après avoir configuré la pub_ssh_key sur controlplane1
systemctl restart sshd

# Récupérer l'IP privée du node11
private_ip=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)
# Stocker l'IP dans un fichier S3
echo "$private_ip" > /tmp/node11-ip.txt
aws s3 cp /tmp/node11-ip.txt s3://kubeadv786/node11-ip.txt

#Boucle d'enregistrement du node11 dans le cluster ainsi que mise en place sshd correct et /etc/hosts
max_attempts=10
attempt=0
while [ $attempt -lt $max_attempts ]; do
  echo "Tentative $((attempt+1)) sur $max_attempts"
  # Télécharger le fichier d'enregistrement
  if aws s3 cp s3://kubeadv786/node11-registration.txt /tmp/node11-registration.txt; then
    # Exécuter la commande d'enregistrement
    if $(cat /tmp/node11-registration.txt); then
      # Récupérer la clé publique
      if aws s3 cp s3://kubeadv786/authorized_keys01.txt /root/.ssh/authorized_keys; then
        # Récupérer le fichier config k8s
        if aws s3 cp s3://kubeadv786/node11-config.txt /root/.kube/config; then
          # Mettre à jour le fichier hosts
          if controlplane1_ip=$(aws s3 cp s3://kubeadv786/controlplane1-ip.txt - | tr -d '\r') && [ -n "$controlplane1_ip" ]; then
            echo "$controlplane1_ip  controlplane1" >> /etc/hosts
            echo "Toutes les opérations ont réussi."
          exit 0
          fi
        fi
      fi
    fi
  fi
  echo "Tentative échouée. Nouvelle tentative dans 20 secondes..."
  sleep 20
  ((attempt++))
done
echo "Échec après $max_attempts tentatives."
exit 1

  EOF

  user_data_replace_on_change = true

  root_block_device {
    volume_type = "gp3"
    volume_size = 20
  }

  tags = {
    Name = "node11"
    user = "student1"
  }

  depends_on = [aws_instance.controlplane1]

}