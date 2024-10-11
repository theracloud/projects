#!/bin/sh
set -e

# Copie tous les fichiers .tf du répertoire monté vers le répertoire de travail
cp *.tf /terraform/

# Exécute terraform apply avec auto-approve
terraform apply -auto-approve
