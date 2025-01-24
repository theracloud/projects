#####################################################################
# Création de l'instance controlplane2 EC2 t3.medium avec OS ubuntu #
#####################################################################
resource "aws_instance" "controlplane2" {
  ami                    = var.ami  # AMI Ubuntu 22.04 LTS pour eu-central-1
  instance_type          = "t3.medium"
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [var.security_group_id]
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
if ! sudo kubeadm init --pod-network-cidr=10.244.0.0/16 --node-name=controlplane2; then
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
hostnamectl set-hostname controlplane2

# Générer la clé publique à intégrer dans node21
ssh-keygen -t rsa -f /root/.ssh/id_rsa -N ""

# modifier la configuration sshd pour permettre l'accès SSH via RSA et autoriser l'accès Root
echo -e "PermitRootLogin yes\nPubkeyAuthentication yes\nAuthorizedKeysFile .ssh/authorized_keys" >> /etc/ssh/sshd_config
# après avoir configurer la pub_ssh_key sur controlplane2
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
echo "$private_ip" > /tmp/controlplane2-ip.txt
aws s3 cp /tmp/controlplane2-ip.txt s3://kubeadv786/controlplane2-ip.txt

# Récupérer la commande d'enregistrement pour le node21
node_registration=$(sudo kubeadm token create --print-join-command)
# Stocker la commande dans un fichier S3
echo "$node_registration" > /tmp/node21-registration.txt
aws s3 cp /tmp/node21-registration.txt s3://kubeadv786/node21-registration.txt

# Récupérer le fichier config k8s pour le node21
aws s3 cp /etc/kubernetes/admin.conf s3://kubeadv786/node21-config.txt

# Récupérer la clé publique pour l'accès SSH
controlplane2_authorized_key=$(cat /root/.ssh/id_rsa.pub)
# Stocker la clé publique dans un fichier S3
echo "$controlplane2_authorized_key" > /tmp/controlplane2-authorized-key.txt
aws s3 cp /tmp/controlplane2-authorized-key.txt s3://kubeadv786/controlplane2-authorized-key.txt

# Mettre à jour le fichier hosts avec l'IP du node21
cat > /root/node-to-ip << 'ENDSCRIPT'
#!/bin/bash
# Mettre à jour le fichier hosts pour node21
node21_ip=$(aws s3 cp s3://kubeadv786/node21-ip.txt - | tr -d '\r')
echo "$node21_ip node21" >> /etc/hosts
ENDSCRIPT
chmod +x /root/node-to-ip

  EOF

  user_data_replace_on_change = true

  root_block_device {
    volume_type = "gp3"
    volume_size = 20
  }

  tags = {
    Name = "controlplane2"
    user = "student2"
  }
}

