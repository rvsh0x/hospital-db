# Système de Gestion d'Hôpital - Base de Données MySQL

Ce projet est une base de données MySQL complète pour la gestion d'un hôpital. Il inclut la gestion des patients, du personnel médical, des consultations, des admissions, des interventions chirurgicales, et de la facturation.

## Fonctionnalités principales

- Gestion des patients : Informations personnelles, consultations, admissions, urgences.
- Gestion du personnel : Médecins, infirmiers, administratifs, et leurs spécialités.
- Planification des interventions chirurgicales : Programmation automatique selon les urgences.
- Facturation : Calcul automatique des factures selon les services utilisés.
- Rapports statistiques : Génération de rapports sur les admissions, consultations, taux d'occupation des chambres, etc.
- Archivage : Historisation des données médicales.
- Sauvegarde : Script de sauvegarde automatique de la base de données avec mysqldump.

## Contenu du projet

- Scripts SQL :
  - `src/creations.sql` : Création des tables et insertion des données.
  - `src/objets.sql` : Fonctions, procédures, triggers, et événements.
  - `src/suppressions.sql` : Suppression des objets et tables.
- Script Bash :
  - `assets/script_sauvegarde.sh` : Automatisation de la sauvegarde de la base de données.
- Rapport :
  - `rapport/Rapport.pdf` : Documentation détaillée du projet.

## Installation

### Prérequis

- MySQL 5.7+ ou MariaDB 10.3+
- Bash (pour les scripts de sauvegarde)

### Étapes d'installation

1. Clonez le dépôt et déplacez vous dans le repertoire.

2. Connectez-vous à MySQL et créez la base de données :
   mysql -u votre_utilisateur -p
   CREATE DATABASE hopital;
   USE hopital;
   source src/creations.sql;
   source src/objets.sql;

## Utilisation

### Exemples de requêtes

#### Générer un rapport pour une période donnée

CALL p_generer_rapport('2024-09-01', '2024-11-30');

#### Voir les statistiques des médecins

CALL p_statistiques_medecins();

## Auteur

- LAICHE Khayr Eddine
- GHODBANE Rachid
- FAIQ Daryan

## Licence

Ce projet est sous licence MIT.
