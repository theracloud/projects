##############################################################
# Création de l'instance EC2 node01 t3.medium avec OS ubuntu #
############################################################## 
resource "aws_instance" "ubuntu0" {
  ami                    = var.ami  # AMI Ubuntu 22.04 LTS pour eu-central-1
  instance_type          = "t3.medium"
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [var.security_group_id]
  iam_instance_profile   = "kubeadv-role"
  key_name      = "eu-central-1-KP"  # Nom de la key pair existante
  user_data = <<-EOF
#!/bin/bash

# Configuration pour éviter les interactions lors de l'upgrade qui va suivre
echo "\$nrconf{restart} = 'a';" |  tee -a /etc/needrestart/needrestart.conf
echo 'DPkg::options { "--force-confdef"; "--force-confold"; }' |  tee /etc/apt/apt.conf.d/local
export DEBIAN_FRONTEND=noninteractive

# Mettre à jour le système
 apt update
 apt-get upgrade -y

# Installer AWS CLI et Nginx
 apt-get install -y awscli
apt install -y nginx

# installation de Docker 
apt-get install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
apt-get install -y docker-ce
usermod -aG docker ubuntu

# Installation de Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose


# Installation explicite du paquet bash-completion
 apt install -y bash-completion

# Définir un nouveau nom d'hôte pour node01
hostnamectl set-hostname ubuntu0

############## Désactivation de l'accès SSH sécurisé en mode root ##########
#!/bin/bash
# Autoriser la connexion root via SSH sans mot de passe
sed -i 's/^#PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
sed -i 's/^PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/^ChallengeResponseAuthentication.*/ChallengeResponseAuthentication no/' /etc/ssh/sshd_config
# Supprimer le mot de passe root pour permettre un accès direct sans mot de passe
passwd -d root
# Redémarrer le service SSH pour appliquer les changements
systemctl restart sshd
# Désactiver la désactivation de root par cloud-init (si activé)
sed -i 's/disable_root: true/disable_root: false/' /etc/cloud/cloud.cfg


# Récupérer l'IP privée du node01
private_ip=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)
# Stocker l'IP dans un fichier S3
echo "$private_ip" > /tmp/ubuntu0-ip.txt
aws s3 cp /tmp/ubuntu0-ip.txt s3://kubeadv786/ubuntu0-ip.txt

#configuration du web server
echo "<html><body><h1>Ma page web simple avec Nginx</h1></body></html>" > /var/www/html/index.html
systemctl start nginx
systemctl enable nginx

#configuration du Firewall
ufw allow ssh
ufw allow http
iptables -A INPUT -p icmp --icmp-type echo-request -s 10.0.0.0/8 -j ACCEPT
iptables -A INPUT -p tcp --dport 22 -s 10.0.0.0/8 -j ACCEPT

  EOF

  user_data_replace_on_change = true
  
  root_block_device {
    volume_type = "gp3"
    volume_size = 20
  }

  tags = {
    Name = "ubuntu0"
    user = "student0"
  }
}