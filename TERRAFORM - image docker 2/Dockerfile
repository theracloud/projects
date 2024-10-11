FROM hashicorp/terraform:latest

# Installez les dépendances nécessaires
RUN apk add --no-cache curl

# Créez un répertoire de travail
WORKDIR /terraform

# Copiez les fichiers de configuration Terraform
COPY main.tf variables.tf /terraform/

# Initialisez Terraform (cela téléchargera le provider AWS)
RUN terraform init

# Nettoyez le cache pour réduire la taille de l'image
RUN rm -rf /root/.terraform

# Définissez l'entrée par défaut
ENTRYPOINT ["terraform"]
