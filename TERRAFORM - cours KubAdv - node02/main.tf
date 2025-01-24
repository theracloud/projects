# Configuration du provider AWS
provider "aws" {
  region = "eu-central-1"  
}

# Création de l'instance EC2 t3.medium avec OS ubuntu  
resource "aws_instance" "ubuntu" {
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

# Définir un nouveau nom d'hôte
hostnamectl set-hostname node02

# modifier la configuration sshd pour permettre l'accès SSH via RSA et autoriser l'accès Root
echo -e "PermitRootLogin yes\nPubkeyAuthentication yes\nAuthorizedKeysFile .ssh/authorized_keys" >> /etc/ssh/sshd_config
# après avoir configurer la pub_ssh_key sur controlplane
systemctl restart sshd

# Récupérer l'IP privée
PRIVATE_IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)
# Stocker l'IP dans un fichier S3
echo "$PRIVATE_IP" > /tmp/node02-ip.txt
aws s3 cp /tmp/node02-ip.txt s3://kubeadv786/node02-ip.txt

# Télécharger le fichier depuis S3
aws s3 cp s3://kubeadv786/node-registration.txt /tmp/node-registration.txt
# Exécuter la commande stockée dans le fichier précédent
$(cat /tmp/node-registration.txt)

# Récupérer la clé publique pour l'accès SSH
aws s3 cp s3://kubeadv786/authorized_keys.txt /root/.ssh/authorized_keys

# Mettre à jour le fichier hosts
CONTROLPLANE_IP=$(aws s3 cp s3://kubeadv786/controlplane-ip.txt - | tr -d '\r')
echo "$CONTROLPLANE_IP  controlplane" >> /etc/hosts

  EOF

  user_data_replace_on_change = true

  root_block_device {
    volume_type = "gp3"
    volume_size = 20
  }

  tags = {
    Name = "node02"
  }
}