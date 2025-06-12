#!/usr/bin/env bash

# Variables de connexion à la base de données
DB_USER="votre_utilisateur"  # Remplacez par votre nom d'utilisateur
DB_PASS="votre_mot_de_passe"  # Remplacez par votre mot de passe
DB_NAME="votre_base_de_donnees"  # Remplacez par le nom de votre base de données

# Exécuter la procédure stockée pour générer la commande de sauvegarde
commande=$(mysql -u $DB_USER -p$DB_PASS -e "CALL p_sauvegarde_base();" $DB_NAME -N -B)

# Exécuter la commande de sauvegarde
eval $commande

# un truc de plus : configuration de la tache cron 
