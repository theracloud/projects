##############################################################
# Création de l'instance EC2 node01 t3.medium avec OS ubuntu #
############################################################## 
resource "aws_instance" "node01" {
  ami                    = var.ami
  instance_type          = "t3.medium"
  key_name               = "eu-central-1-KP"
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [var.security_group_id]
  iam_instance_profile   = var.instance_profile
   
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

# Définir un nouveau nom d'hôte pour node01
hostnamectl set-hostname node01

# modifier la configuration sshd pour permettre l'accès SSH via RSA et autoriser l'accès Root
echo -e "PermitRootLogin yes\nPubkeyAuthentication yes\nAuthorizedKeysFile .ssh/authorized_keys" >> /etc/ssh/sshd_config
# après avoir configuré la pub_ssh_key sur controlplane0
systemctl restart sshd

# Récupérer l'IP privée du node01
private_ip=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)
# Stocker l'IP dans un fichier S3
echo "$private_ip" > /tmp/node01-ip.txt
aws s3 cp /tmp/node01-ip.txt s3://kubeadv/init/node01-ip.txt

#Boucle d'enregistrement du node01 dans le cluster ainsi que mise en place sshd correct et /etc/hosts
max_attempts=10
attempt=0
while [ $attempt -lt $max_attempts ]; do
  echo "Tentative $((attempt+1)) sur $max_attempts"
  # Télécharger le fichier d'enregistrement
  if aws s3 cp s3://kubeadv/init/node01-registration.txt /tmp/node01-registration.txt; then
    # Exécuter la commande d'enregistrement
    if $(cat /tmp/node01-registration.txt); then
      # Récupérer la clé publique
      if aws s3 cp s3://kubeadv/init/controlplane0-authorized-key.txt /root/.ssh/authorized_keys; then
        # Récupérer le fichier config k8s
        if aws s3 cp s3://kubeadv/init/node01-config.txt /root/.kube/config; then
          # Mettre à jour le fichier hosts
          if controlplane0_ip=$(aws s3 cp s3://kubeadv/init/controlplane0-ip.txt - | tr -d '\r') && [ -n "$controlplane0_ip" ]; then
            echo "$controlplane0_ip  controlplane0" >> /etc/hosts
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
    Name = "node01"
    user = "student0"
    app =  "kubeadv"
  }

# depends_on = [aws_instance.controlplane0]

}