/* Suppression des déclencheurs */
DROP TRIGGER IF EXISTS t_bf_ins_personnel;
DROP TRIGGER IF EXISTS t_af_ins_admission;
DROP TRIGGER IF EXISTS t_bf_ins_facturation;
DROP TRIGGER IF EXISTS t_af_ins_historique_medical;

/* Suppression des procédures */
DROP PROCEDURE IF EXISTS p_peuplement_admission;
DROP PROCEDURE IF EXISTS p_prise_rendez_vous;
DROP PROCEDURE IF EXISTS p_programmation_intervention_chirugicale;
DROP PROCEDURE IF EXISTS p_sauvegarde_base;
DROP PROCEDURE IF EXISTS p_peuplement_historique_medical;
DROP PROCEDURE IF EXISTS p_generer_rapport;
DROP PROCEDURE IF EXISTS p_details_patient;
DROP PROCEDURE IF EXISTS p_peupler_comptes_utilisateurs;

/* Suppression des fonctions */
DROP FUNCTION IF EXISTS f_verifier_disponibilite_personnel;
DROP FUNCTION IF EXISTS f_calcul_facture;
DROP FUNCTION IF EXISTS f_taux_occupation_chambres;
DROP FUNCTION IF EXISTS f_recommandation;
DROP FUNCTION IF EXISTS f_generer_mot_de_passe;

/* Suppression des tables */
DROP TABLE IF EXISTS historique_medical;
DROP TABLE IF EXISTS facturation;
DROP TABLE IF EXISTS interventions_chirurgicales;
DROP TABLE IF EXISTS urgences;
DROP TABLE IF EXISTS consultations;
DROP TABLE IF EXISTS admissions;
DROP TABLE IF EXISTS chambres;
DROP TABLE IF EXISTS comptes_utilisateurs;
DROP TABLE IF EXISTS personnel;
DROP TABLE IF EXISTS patients;