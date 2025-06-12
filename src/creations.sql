/* 1. Création des tables */
-- Table Patients
CREATE TABLE IF NOT EXISTS patients (
    id_patient INT UNSIGNED AUTO_INCREMENT,
    nom VARCHAR(255) NOT NULL,
    prenom VARCHAR(255) NOT NULL,
    date_naissance DATE,
    adresse VARCHAR(255) NOT NULL,
    telephone VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL,
    contact_urgence VARCHAR(255) NOT NULL,
    assure BOOLEAN NOT NULL DEFAULT 0,
    CONSTRAINT pk_patients PRIMARY KEY (id_patient),
    CONSTRAINT unq_email_patients UNIQUE idxunq_email_patients (email),
    CONSTRAINT unq_telephone_patients UNIQUE idxunq_telephone_patients (telephone),
    CONSTRAINT chk_email CHECK (email LIKE '%_@__%.__%'),
    INDEX idx_nom_prenom_patients (nom, prenom)
);

-- Table Personnel
CREATE TABLE IF NOT EXISTS personnel (
    id_personnel INT UNSIGNED AUTO_INCREMENT,
    nom VARCHAR(255) NOT NULL,
    prenom VARCHAR(255) NOT NULL,
    poste ENUM('Médecin', 'Infirmier', 'Administratif', 'Technicien', 'Autre') NOT NULL,
    specialite VARCHAR(255), 
    annees_experience INT UNSIGNED,
    telephone VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL,
    service VARCHAR(255) NOT NULL,
    CONSTRAINT pk_personnel PRIMARY KEY (id_personnel),
    CONSTRAINT unq_email_personnel UNIQUE idxunq_email_personnel (email),
    CONSTRAINT chk_annees_experience CHECK (annees_experience >= 0 AND annees_experience <= 50),
    INDEX idx_nom_prenom_personnel (nom, prenom)
);

-- Table Comptes Utilisateurs
CREATE TABLE IF NOT EXISTS comptes_utilisateurs (
    id_compte INT UNSIGNED AUTO_INCREMENT,
    id_personnel INT UNSIGNED NOT NULL,
    nom_utilisateur VARCHAR(255) NOT NULL,
    mot_de_passe VARCHAR(255) NOT NULL,
    CONSTRAINT pk_comptes_utilisateurs PRIMARY KEY (id_compte),
    CONSTRAINT fk_comptes_utilisateurs_personnel FOREIGN KEY (id_personnel) REFERENCES personnel(id_personnel) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT unq_nom_utilisateur UNIQUE (nom_utilisateur),
    INDEX idx_id_personnel (id_personnel)
);

-- Table Chambres
CREATE TABLE IF NOT EXISTS chambres (
    id_chambre INT UNSIGNED AUTO_INCREMENT,
    numero_chambre VARCHAR(10) NOT NULL,
    type_chambre ENUM('Simple', 'Double', 'Suite') NOT NULL,
    disponibilite BOOLEAN NOT NULL,
    CONSTRAINT pk_chambres PRIMARY KEY (id_chambre),
    CONSTRAINT unq_numero_chambre UNIQUE idxunq_numero_chambre (numero_chambre)
);

-- Table Admissions
CREATE TABLE IF NOT EXISTS admissions (
    id_admission INT UNSIGNED AUTO_INCREMENT,
    id_patient INT UNSIGNED NOT NULL,
    date_admission DATE NOT NULL,
    date_sortie DATE NOT NULL,
    id_chambre INT UNSIGNED,
    id_personnel INT UNSIGNED NOT NULL,
    CONSTRAINT pk_admissions PRIMARY KEY (id_admission),
    CONSTRAINT fk_admissions_patient FOREIGN KEY (id_patient) REFERENCES patients(id_patient) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_admissions_chambre FOREIGN KEY (id_chambre) REFERENCES chambres(id_chambre) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_admissions_personnel FOREIGN KEY (id_personnel) REFERENCES personnel(id_personnel) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT unq_patient_date_admission UNIQUE idxunq_patient_date_admission (id_patient, date_admission),
    CONSTRAINT chk_date_sortie CHECK (date_sortie >= date_admission),
    INDEX idx_date_admission (date_admission)
);

-- Table Consultations
CREATE TABLE IF NOT EXISTS consultations (
    id_consultation INT UNSIGNED AUTO_INCREMENT,
    id_patient INT UNSIGNED NOT NULL,
    id_personnel INT UNSIGNED NOT NULL,
    date_consultation DATETIME NOT NULL,
    motif_consultation TEXT NOT NULL,
    besoin_admission BOOLEAN NOT NULL DEFAULT 0,
    prescription TEXT,
    CONSTRAINT pk_consultations PRIMARY KEY (id_consultation),
    CONSTRAINT fk_consultations_patient FOREIGN KEY (id_patient) REFERENCES patients(id_patient) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_consultations_personnel FOREIGN KEY (id_personnel) REFERENCES personnel(id_personnel) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT unq_patient_date_consultation UNIQUE idxunq_patient_date_consultation (id_patient, date_consultation),
    INDEX idx_date_consultation (date_consultation)
);

-- Table Urgences
CREATE TABLE IF NOT EXISTS urgences (
    id_urgence INT UNSIGNED AUTO_INCREMENT,
    id_patient INT UNSIGNED NOT NULL,
    id_personnel INT UNSIGNED NOT NULL,
    date_urgence DATETIME NOT NULL,
    type_urgence ENUM('Générale', 'Cardiologie', 'Orthopédie', 'Neurochirurgie', 'Traumatologie', 'Pédiatrie') NOT NULL,
    urgence_chirurgicale BOOLEAN NOT NULL,
    niveau_urgence TINYINT UNSIGNED NOT NULL,
    CONSTRAINT pk_urgences PRIMARY KEY (id_urgence),
    CONSTRAINT fk_urgences_patient FOREIGN KEY (id_patient) REFERENCES patients(id_patient) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_urgences_personnel FOREIGN KEY (id_personnel) REFERENCES personnel(id_personnel) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT unq_patient_date_urgence UNIQUE idxunq_patient_date_urgence (id_patient, date_urgence),
    CONSTRAINT chk_niveau_urgence CHECK (niveau_urgence BETWEEN 1 AND 5),
    INDEX idx_date_urgence (date_urgence)
);

-- Table Interventions Chirurgicales
CREATE TABLE IF NOT EXISTS interventions_chirurgicales (
    id_intervention INT UNSIGNED AUTO_INCREMENT,
    id_patient INT UNSIGNED NOT NULL,
    id_personnel INT UNSIGNED NOT NULL,
    salle_operation INT UNSIGNED NOT NULL,
    date_intervention DATETIME NOT NULL,
    type_intervention ENUM('Chirurgie Générale', 'Cardiologie', 'Orthopédie', 'Neurochirurgie', 'Traumatologie', 'Pédiatrie') NOT NULL,
    taux_reussite DECIMAL(5,2),
    CONSTRAINT pk_interventions PRIMARY KEY (id_intervention),
    CONSTRAINT fk_interventions_patient FOREIGN KEY (id_patient) REFERENCES patients(id_patient) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_interventions_personnel FOREIGN KEY (id_personnel) REFERENCES personnel(id_personnel) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT unq_patient_date_intervention UNIQUE idxunq_patient_date_intervention (id_patient, date_intervention),
    INDEX idx_date_intervention (date_intervention),
    CONSTRAINT chk_taux_reussite CHECK (taux_reussite BETWEEN 0 AND 100)
);

-- Table Facturation
CREATE TABLE IF NOT EXISTS facturation (
    id_facture INT UNSIGNED AUTO_INCREMENT,
    id_patient INT UNSIGNED NOT NULL,
    montant DECIMAL(10,2) NOT NULL,
    statut ENUM('payée', 'en attente') NOT NULL,
    date_facture DATE NOT NULL,
    CONSTRAINT pk_facturation PRIMARY KEY (id_facture),
    CONSTRAINT fk_facturation_patient FOREIGN KEY (id_patient) REFERENCES patients(id_patient) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT unq_patient_montant_date UNIQUE idxunq_patient_montant (id_patient, montant, date_facture),
    INDEX idx_montant (montant)
);

-- Table Historique Médical
CREATE TABLE IF NOT EXISTS historique_medical (
    id_historique INT UNSIGNED AUTO_INCREMENT,
    id_patient INT UNSIGNED NOT NULL,
    date DATETIME NOT NULL,
    type_intervention ENUM('Consultation', 'Intervention Chirurgicale') NOT NULL,
    CONSTRAINT pk_historique PRIMARY KEY (id_historique),
    CONSTRAINT fk_historique_patient FOREIGN KEY (id_patient) REFERENCES patients(id_patient) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT unq_patient_date UNIQUE idxunq_patient_date (id_patient, date),
    INDEX idx_date (date)
);

/* 2. Insertion des données */
source ../data/patients.sql
source ../data/personnel.sql
source ../data/chambres.sql
source ../data/consultations.sql
source ../data/urgences.sql
source ../data/interventions_chirurgicales.sql
source ../data/facturation.sql
