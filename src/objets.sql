/* Creation des objets */
/* 1- Les fonctions : */
/* une fonction pour la verification de la disponibilite d'un personnel -> pour
eviter les repetitions du code de la verif */
DELIMITER $
CREATE FUNCTION f_verifier_disponibilite_personnel(
    in_id_personnel INT,
    in_date DATETIME
)
RETURNS BOOLEAN
BEGIN
    DECLARE v_verification INT;
    /* Vérifier les interventions chirurgicales */
    SELECT COUNT(id_personnel)
    INTO v_verification
    FROM interventions_chirurgicales
    WHERE id_personnel = in_id_personnel
    AND date_intervention = in_date;

    IF v_verification > 0 THEN
        RETURN FALSE;
    END IF;

    /* Vérifier les consultations */
    SELECT COUNT(id_personnel)
    INTO v_verification
    FROM consultations
    WHERE id_personnel = in_id_personnel
    AND date_consultation = in_date;

    IF v_verification > 0 THEN
        RETURN FALSE;
    END IF;

    /* Vérifier les admissions */
    SELECT COUNT(id_personnel)
    INTO v_verification
    FROM admissions
    WHERE id_personnel = in_id_personnel
    AND date_admission = DATE(in_date);

    IF v_verification > 0 THEN
        RETURN FALSE;
    END IF;

    /* Vérifier les urgences */
    SELECT COUNT(id_personnel)
    INTO v_verification
    FROM urgences
    WHERE id_personnel = in_id_personnel
    AND date_urgence = in_date;

    IF v_verification > 0 THEN
        RETURN FALSE;
    END IF;

    /*Si aucune des vérifications n'a trouvé de conflit, le personnel est disponible*/
    RETURN TRUE;
END$
DELIMITER ;

/* Test :
SELECT f_verifier_disponibilite_personnel(16, '2024-09-01 10:00:00') AS disponibilite; 
SELECT f_verifier_disponibilite_personnel(16, '2024-09-21 10:00:00') AS disponibilite; */

/* une fonction pour cacluler la facture d un patient */
/* On fixe un prix pour une consultation, une admission et une intervention chirurgicale 
-> on suppose que le prix est fixe -> consultation = 50, admission = 100 par nuit , intervention = 500 */
/* -> on pense au champs assuré ou pas dans la table patient */
DELIMITER $
CREATE FUNCTION IF NOT EXISTS f_calcul_facture(
    in_id_patient INT
)
RETURNS DECIMAL(10, 2)
BEGIN
    DECLARE v_total_consultations INT;
    DECLARE v_total_interventions INT;
    DECLARE v_nombres_nuits INT;
    DECLARE v_total_facture DECIMAL(15, 2);
    DECLARE v_assure BOOLEAN;
    DECLARE v_date_admission DATE;
    DECLARE v_date_sortie DATE;
    DECLARE v_tarif_consultation DECIMAL(4,2);
    DECLARE v_tarif_admission DECIMAL(5,2);
    DECLARE v_tarif_intervention DECIMAL(5,2);

    /* On recupere le nombre de consultations */
    BEGIN
        DECLARE EXIT HANDLER
        FOR NOT FOUND
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Le patient n''existe pas';

        SELECT assure
        INTO v_assure
        FROM patients
        WHERE id_patient = in_id_patient;
    END;

    /* nbrs de consultations */
    SELECT COUNT(id_patient)
    INTO v_total_consultations
    FROM consultations
    WHERE id_patient = in_id_patient;

    /* nbrs d interventions */
    SELECT COUNT(id_patient)
    INTO v_total_interventions
    FROM interventions_chirurgicales
    WHERE id_patient = in_id_patient;

    /* nbrs de nuits */
    SELECT date_admission, date_sortie
    INTO v_date_admission, v_date_sortie
    FROM admissions
    WHERE id_patient = in_id_patient;

    IF v_date_admission IS NOT NULL THEN
        SET v_nombres_nuits = DATEDIFF(v_date_sortie, v_date_admission);
    ELSE
        SET v_nombres_nuits = 0;
    END IF;

    /* On fixe les tarifs */
    SET v_tarif_consultation = 50;
    SET v_tarif_admission = 100;
    SET v_tarif_intervention = 500;

    /* Calcul de la facture */
    SET v_total_facture = (v_total_consultations * v_tarif_consultation) + (v_total_interventions * v_tarif_intervention) + (v_nombres_nuits * v_tarif_admission );

    /* cas de v_assure */
    IF v_assure = TRUE THEN
        SET v_total_facture = v_total_facture * 0.2;
    END IF;

    RETURN v_total_facture;
END$
DELIMITER ;

/* Test : 
SELECT f_calcul_facture(64) AS facture_patient_64; */

/* une fonction pour calculer le taux occupation des chambres */
DELIMITER $
CREATE FUNCTION IF NOT EXISTS  f_taux_occupation_chambres()
RETURNS DECIMAL(5, 2)
BEGIN
    DECLARE v_nombres_total_chambres INT;
    DECLARE v_nombres_chambres_occupees INT;
    DECLARE v_taux_occupation DECIMAL(5, 2);

    /* On recupere le nombre total de chambres */
    SELECT COUNT(id_chambre)
    INTO v_nombres_total_chambres
    FROM chambres;

    /* On recupere le nombre de chambres occupees */
    SELECT COUNT(id_chambre)
    INTO v_nombres_chambres_occupees
    FROM chambres
    WHERE disponibilite = FALSE;

    /* Calcul du taux d'occupation */
    SET v_taux_occupation = (v_nombres_chambres_occupees / v_nombres_total_chambres) * 100;

    RETURN v_taux_occupation;
END 
$
DELIMITER ;

/* Test : 
SELECT f_taux_occupation_chambres() AS taux_occupation_chambres; */

/* une fonction pour la recommandation d'un medecin */
DELIMITER $

CREATE FUNCTION IF NOT EXISTS f_recommandation(
    in_id_personnel INT
)
RETURNS VARCHAR(255)
BEGIN
    DECLARE v_total_interventions INT;
    DECLARE v_interventions_reussies INT;
    DECLARE v_taux_reussite DECIMAL(5, 2);
    DECLARE v_recommandation_ou_pas VARCHAR(255);

    /* On recupere le nombre d'interventions chirurgicales */
    SELECT COUNT(id_intervention)
    INTO v_total_interventions
    FROM interventions_chirurgicales
    WHERE id_personnel = in_id_personnel;

    IF v_total_interventions = 0 THEN
        RETURN 'Pas d''interventions chirurgicales';
    END IF;

    /* On recupere le nombre d'interventions chirurgicales reussies */
    SELECT COUNT(id_intervention)
    INTO v_interventions_reussies
    FROM interventions_chirurgicales
    WHERE id_personnel = in_id_personnel
    AND taux_reussite >= 80;

    /* Calcul du taux de reussite */
    SET v_taux_reussite = (v_interventions_reussies / v_total_interventions) * 100;

    IF v_taux_reussite >= 75 THEN
        SET v_recommandation_ou_pas = 'Recommandé';
    ELSE
        SET v_recommandation_ou_pas = 'Non recommandé';
    END IF;

    RETURN v_recommandation_ou_pas;
END $

DELIMITER ;
/* Test : 
SELECT f_recommandation(3) AS recommandation_medecin_3; */

/* une fonction pour creer un mot de passe aleatoire */
DELIMITER $

CREATE FUNCTION IF NOT EXISTS f_generer_mot_de_passe(
    in_id_personnel INT
) 
RETURNS VARCHAR(255)
NOT DETERMINISTIC /* pour produire un mot de passe different a chaque fois */
READS SQL DATA /* pour lire les donnees de la base de donnees */
BEGIN
    DECLARE v_mot_de_passe_genere VARCHAR(255);
    DECLARE v_nom_ou_prenom VARCHAR(255);
    DECLARE v_longueur_cible TINYINT UNSIGNED;

    /* Récupérer le nom ou le prénom du personnel */
    SELECT IF(RAND() < 0.5, nom, prenom)
    INTO v_nom_ou_prenom
    FROM personnel
    WHERE id_personnel = in_id_personnel;

    /* Générer un mot de passe aléatoire basé sur le nom ou le prénom */
    SET v_mot_de_passe_genere = v_nom_ou_prenom;
    SET v_longueur_cible = 12;

    WHILE LENGTH(v_mot_de_passe_genere) < v_longueur_cible DO
        SET v_mot_de_passe_genere = CONCAT(
            v_mot_de_passe_genere,
            SUBSTRING('abcdefghijklmnopqrstuvwxyz', FLOOR(1 + RAND() * 26), 1), /* caractère minuscule */
            SUBSTRING('ABCDEFGHIJKLMNOPQRSTUVWXYZ', FLOOR(1 + RAND() * 26), 1), /* caractère majuscule */
            SUBSTRING('0123456789', FLOOR(1 + RAND() * 10), 1), /* chiffre */
            SUBSTRING('!@#$%^&*()+-=[]{};:,.<>?', FLOOR(1 + RAND() * 26), 1) /* caractère spécial */
        );
    END WHILE;

    /* Retourner le mot de passe généré */
    RETURN SUBSTRING(v_mot_de_passe_genere, 1, v_longueur_cible);
END$
DELIMITER ;

/* Test : 
SELECT f_generer_mot_de_passe(2) AS mot_de_passe_personnel_2; */

/* 2- Les triggers */
/* un trigger avant insertion dans la table personnel */
DELIMITER $
CREATE TRIGGER IF NOT EXISTS t_bf_ins_personnel
BEFORE INSERT
ON personnel
FOR EACH ROW
BEGIN
    DECLARE v_capacite_max_personnel INT;
    DECLARE v_total_personnel INT;
    DECLARE v_remarque VARCHAR(255);
    /* On recupere le nombre total de personnel */
    SELECT COUNT(id_personnel)
    INTO v_total_personnel
    FROM personnel;

    SET v_capacite_max_personnel = 100;

    IF v_total_personnel >= v_capacite_max_personnel THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Capacite maximale du personnel atteinte';
    END IF;

    /* verification du poste */
    IF NEW.poste NOT IN ('Médecin', 'Infirmier', 'Administratif', 'Technicien', 'Autre') THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Poste invalide , on recrute que des medecins, infirmiers, administratifs, techniciens ou autres';
    END IF;
    /* verification de la specialite */
    IF (NEW.poste = 'Médecin' OR  NEW.poste = 'Infirmier') AND NEW.specialite IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Un medecin ou un infirmier doit avoir une specialite';
    END IF;

    /* verification du format de telephone et l email */
    IF NEW.telephone NOT REGEXP '^[0-9]{10}$' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Veuillez renseigner un numero de telephone valide';
    END IF;

    /* Vérification du format de l'email avec LIKE */
    IF NEW.email NOT LIKE '%_@__%.__%' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Veuillez renseigner une adresse email valide';
    END IF;
    /* verification des annees d experience -> on va laisser l insertion 
    et on dit une petite remarque que ce personnel est stagiere si il a moins de 2 ans d experience */
    IF NEW.annees_experience < 2 THEN
        SET v_remarque = CONCAT('Ce personnel est stagiaire en tant que ', NEW.poste);
    END IF;
END
$
DELIMITER ;

/* Test : 
INSERT INTO personnel (nom, prenom, poste, specialite, annees_experience, telephone, email, service)
VALUES ('Khairi', 'Laiche', 'Médecin', 'Cardiologie', 5, '0612345678', 'khairi.laiche@hopital.com', 'Service de Cardiologie');

INSERT INTO personnel (nom, prenom, poste, specialite, annees_experience, telephone, email, service)
VALUES ('Test', 'Invalide', 'Infirmier', 'Bloc Opératoire (IBODE)', 3, '06123', 'invalid.test@hopital.com', 'Service de Neurochirurgie'); */

/* - Apres insertion dans admissions */
/* on doit faire une mise a jour dans la table chambre */
DELIMITER $
CREATE TRIGGER IF NOT EXISTS t_af_ins_admission
AFTER INSERT
ON admissions
FOR EACH ROW
BEGIN
    UPDATE chambres
    SET disponibilite = FALSE
    WHERE chambres.id_chambre = NEW.id_chambre;
END
$
DELIMITER ;

/* Test :
INSERT INTO admissions (id_patient, id_personnel, id_chambre, date_admission, date_sortie)
VALUES (1, 1, 3, '2024-09-01', '2024-09-10'); 
SELECT disponibilite FROM chambres WHERE id_chambre = 3 AS chambre_3; */

/* un trigger apres insertion dans historique medical */
DELIMITER $
CREATE TRIGGER IF NOT EXISTS t_af_ins_historique_medical
AFTER INSERT
ON historique_medical
FOR EACH ROW
BEGIN
    DELETE FROM consultations
    WHERE id_patient = NEW.id_patient
    AND date_consultation = NEW.date;

    DELETE FROM interventions_chirurgicales
    WHERE id_patient = NEW.id_patient
    AND date_intervention = NEW.date;
END
$
DELIMITER ;

/* un trigger avant insertion dans facturation */
DELIMITER $
CREATE TRIGGER IF NOT EXISTS t_bf_ins_facturation
BEFORE INSERT
ON facturation
FOR EACH ROW
BEGIN
    DECLARE v_date_consultation DATETIME;
    DECLARE v_date_sortie_admission DATE;

    /* Verification du montant */
    IF NEW.montant < 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Le montant de la facture doit etre positif';
    ELSEIF f_calcul_facture(NEW.id_patient) != NEW.montant THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Le montant de la facture est incorrect';
    END IF;

    /* Verification de la date de la facture -> il faut qu elle soit egale 
    a la date de fin de consultation , sortie de l'admission -> si ce n est pas le cas on va la mettre a jour */

    /* le cas de la date de consultation */
    SELECT DATE(date_consultation)
    INTO v_date_consultation
    FROM consultations
    WHERE id_patient = NEW.id_patient
    AND NEW.id_patient NOT IN (SELECT id_patient FROM admissions); /* on verifie si le patient n'a pas d'admission */

    IF NEW.date_facture != v_date_consultation THEN
        SET NEW.date_facture = v_date_consultation;
    END IF;

    /* le cas de la date de sortie de l'admission */
    SELECT date_sortie
    INTO v_date_sortie_admission
    FROM admissions
    WHERE id_patient = NEW.id_patient;

    IF NEW.date_facture != v_date_sortie_admission THEN
        SET NEW.date_facture = v_date_sortie_admission;
    END IF;

    /* Verification du statut */
    IF NEW.statut NOT IN ('payée', 'en attente') THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Statut de la facture invalide';
    END IF;
END
$
DELIMITER ;

/* Test : 
-- facture valide :
INSERT INTO facturation (id_patient, montant, statut, date_facture)
VALUES (69, 10.00, 'en attente', '2024-12-27');
-- facture invalide (montant incorrect)
INSERT INTO facturation (id_patient, montant, statut, date_facture)
VALUES (68, 100.00, 'en attente', '2024-12-28');  */

/* 3- Les procedures */
/* une procedure pour peupler les admissions */
DELIMITER $

CREATE PROCEDURE p_peuplement_admission()
BEGIN
    DECLARE v_id_patient INT;
    DECLARE v_id_personnel INT;
    DECLARE v_id_chambre INT;
    DECLARE v_date_admission DATE;
    DECLARE v_date_consultation DATETIME;
    DECLARE v_date_sortie DATE;
    DECLARE v_date_intervention DATETIME;
    DECLARE v_compteur INT UNSIGNED DEFAULT 0;
    DECLARE v_total_personnel INT;
    DECLARE v_total_admissions_possible INT;
    DECLARE v_continuer BOOLEAN DEFAULT TRUE;

    /* Les curseurs */
    DECLARE c_interventions CURSOR FOR
    SELECT id_patient, date_intervention
    FROM interventions_chirurgicales;

    DECLARE c_consultations CURSOR FOR
    SELECT id_patient, date_consultation
    FROM consultations
    WHERE besoin_admission = TRUE;

    /* On recupere le nombre total de personnel */
    SELECT COUNT(id_personnel)
    INTO v_total_personnel
    FROM personnel
    WHERE poste IN ('Infirmier');

    SET v_total_admissions_possible = FLOOR(v_total_personnel * 0.75); /* 75% des infirmiers peuvent s'occuper des admissions */

    /* Gestion des interventions chirurgicales */
    BEGIN
        DECLARE CONTINUE HANDLER 
        FOR NOT FOUND
        SET v_continuer = FALSE;

        OPEN c_interventions;
        ma_boucle_interventions : LOOP 
            FETCH c_interventions 
            INTO v_id_patient, v_date_intervention;
            IF v_continuer = FALSE THEN
                LEAVE ma_boucle_interventions;
            END IF;
            SET v_date_admission = DATE(v_date_intervention);

            /* On recupere l'id du personnel */
            SELECT id_personnel
            INTO v_id_personnel
            FROM personnel
            WHERE poste IN ('Infirmier')
            AND f_verifier_disponibilite_personnel(id_personnel, v_date_admission) = TRUE
            ORDER BY RAND()
            LIMIT 1;

            IF v_id_personnel IS NULL THEN
                SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Aucun personnel disponible pour l''admission';
            END IF;

            /* On recupere l'id de la chambre */
            SELECT id_chambre
            INTO v_id_chambre
            FROM chambres
            WHERE disponibilite = TRUE
            ORDER BY RAND()
            LIMIT 1;

            IF v_id_chambre IS NULL THEN
                SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Aucune chambre disponible pour l''admission';
            END IF;

            SET v_date_sortie = DATE_ADD(v_date_admission, INTERVAL FLOOR(1 + RAND() * 30) DAY);
            /* Insertion de l'admission */
            INSERT INTO admissions (id_patient, id_personnel, id_chambre, date_admission, date_sortie)
            VALUES (v_id_patient, v_id_personnel, v_id_chambre, v_date_admission, v_date_sortie);

            /* Affichage de message de confirmation */
            SELECT CONCAT('Admission de ', v_id_patient, ' effectuee par ', v_id_personnel, ' dans la chambre ', v_id_chambre, ' le ', v_date_admission, ' avec une sortie prevue le ', v_date_sortie) AS resultat;

            SET v_compteur = v_compteur + 1;
            IF v_compteur >= v_total_admissions_possible THEN
                LEAVE ma_boucle_interventions;
            END IF;
        END LOOP;
        CLOSE c_interventions;
    END;

    /* Réinitialiser v_continuer pour la deuxième boucle */
    SET v_continuer = TRUE;

    /* Gestion des consultations */
    IF v_compteur > v_total_admissions_possible THEN
        SELECT CONCAT('Toutes les admissions possibles ont ete effectuees , on ne peut prendre en charge les consultations') AS resultat;
    ELSE
        BEGIN
            DECLARE CONTINUE HANDLER 
            FOR NOT FOUND
            SET v_continuer = FALSE;

            OPEN c_consultations;
            ma_boucle_consultations : LOOP 
                FETCH c_consultations 
                INTO v_id_patient, v_date_consultation;
                IF v_continuer = FALSE THEN
                    LEAVE ma_boucle_consultations;
                END IF;
                SET v_date_admission = DATE_ADD(DATE(v_date_consultation), INTERVAL 1 DAY);
                /* On recupere l'id du personnel qui va s'occuper de l'admission */
                SELECT id_personnel
                INTO v_id_personnel
                FROM personnel
                WHERE poste IN ('Infirmier')
                AND f_verifier_disponibilite_personnel(id_personnel, v_date_admission) = TRUE
                ORDER BY RAND()
                LIMIT 1;

                IF v_id_personnel IS NULL THEN
                    SIGNAL SQLSTATE '45000'
                    SET MESSAGE_TEXT = 'Aucun personnel disponible pour l''admission';
                END IF;

                /* On recupere l'id de la chambre */
                SELECT id_chambre
                INTO v_id_chambre
                FROM chambres
                WHERE disponibilite = TRUE
                ORDER BY RAND()
                LIMIT 1;

                IF v_id_chambre IS NULL THEN
                    SIGNAL SQLSTATE '45000'
                    SET MESSAGE_TEXT = 'Aucune chambre disponible pour l''admission';
                END IF;

                SET v_date_sortie = DATE_ADD(v_date_admission, INTERVAL FLOOR(1 + RAND() * 30) DAY);
                /* Insertion de l'admission */
                INSERT INTO admissions (id_patient, id_personnel, id_chambre, date_admission, date_sortie)
                VALUES (v_id_patient, v_id_personnel, v_id_chambre, v_date_admission, v_date_sortie);

                /* Affichage de message de confirmation */
                SELECT CONCAT('Admission de ', v_id_patient, ' effectuee par ', v_id_personnel, ' dans la chambre ', v_id_chambre, ' le ', v_date_admission, ' avec une sortie prevue le ', v_date_sortie) AS resultat;

                SET v_compteur = v_compteur + 1;
                IF v_compteur >= v_total_admissions_possible THEN
                    LEAVE ma_boucle_consultations;
                END IF;
            END LOOP;
            CLOSE c_consultations;
        END;
    END IF;
END $
DELIMITER ;

/* Test : */
DELETE FROM admissions; 
ALTER TABLE admissions AUTO_INCREMENT = 1;
CALL p_peuplement_admission(); 
SELECT * FROM admissions; 

/* la procedure pour la programmation des intervention_chirugicales */
DELIMITER $
CREATE PROCEDURE p_programmation_intervention_chirugicale()
BEGIN
    DECLARE v_nb_medecins INT;
    DECLARE v_id_patient INT;
    DECLARE v_id_personnel INT;
    DECLARE v_date_urgence DATETIME;
    DECLARE v_type_urgence ENUM('Générale', 'Cardiologie', 'Orthopédie', 'Neurochirurgie', 'Traumatologie', 'Pédiatrie');
    DECLARE v_niveau_urgence INT;
    DECLARE v_date_intervention DATETIME;
    DECLARE v_salle_operation INT;
    DECLARE v_taux_reussite DECIMAL(5, 2);
    DECLARE v_continuer BOOLEAN DEFAULT TRUE;

    DECLARE c_urgences CURSOR FOR
    SELECT id_patient, date_urgence , type_urgence , niveau_urgence
    FROM urgences
    WHERE urgence_chirurgicale = TRUE
    LIMIT v_nb_medecins;

    /* On recupere le nombre de medecins */
    SELECT COUNT(id_personnel)
    INTO v_nb_medecins
    FROM personnel
    WHERE poste = 'Médecin';

    SET v_nb_medecins = FLOOR(v_nb_medecins/2); /* faut pas que tous les medecins fassent des interventions chirugicales */

    BEGIN
        DECLARE CONTINUE HANDLER
        FOR NOT FOUND
        SET v_continuer = FALSE;

        OPEN c_urgences;
        boucle_urgences : LOOP
            FETCH c_urgences
            INTO v_id_patient, v_date_urgence, v_type_urgence, v_niveau_urgence;
            IF v_continuer = FALSE THEN
                LEAVE boucle_urgences;
            END IF;

            /* On recupere l'id du personnel qui va s'occuper de l'intervention chirugicale */
            SELECT id_personnel
            INTO v_id_personnel
            FROM personnel
            WHERE poste = 'Médecin'
            AND specialite = v_type_urgence
            AND f_verifier_disponibilite_personnel(id_personnel, v_date_urgence) = TRUE
            ORDER BY RAND()
            LIMIT 1;

            IF v_id_personnel IS NULL THEN
                SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Aucun personnel disponible pour l''intervention chirurgicale , il faut evacuer le patient';
            END IF;

            /* On choisit un NUMERO DE salle d'operation aleatoirement */
            SELECT ROUND(101 + RAND() * 9)
            INTO v_salle_operation;

            /* On choisit une date d'intervention selon la gravite de l'urgence */
            IF v_niveau_urgence IN (1,2,3) THEN /* le cas d une date dans un intervalle de 3 jours */
                SET v_date_intervention = TIMESTAMPADD(DAY, FLOOR(1 + RAND() * 3), v_date_urgence);
            ELSE /* le cas de 12 heures max */
                SET v_date_intervention = TIMESTAMPADD(HOUR, FLOOR(1 + RAND() * 12), v_date_urgence);
            END IF;

            /* Gestion du taux de reussite -> aleatoire */
            SET v_taux_reussite = ROUND(75 + RAND() * 10, 2);

            /* Insertion de l'intervention chirurgicale */
            INSERT INTO interventions_chirurgicales (id_patient, id_personnel, date_intervention, salle_operation, taux_reussite)
            VALUES (v_id_patient, v_id_personnel, v_date_intervention, v_salle_operation, v_taux_reussite);

            /* Affichage de message de confirmation */
            SELECT CONCAT('Intervention chirurgicale pour le patient ', v_id_patient, ' effectuee par ', v_id_personnel, ' dans la salle ', v_salle_operation, ' le ', v_date_intervention) AS resultat;

        END LOOP;
        CLOSE c_urgences;
    END;
END$
DELIMITER ;

/* Test : */
CALL p_programmation_intervention_chirugicale();
SELECT * FROM interventions_chirurgicales; 

/* une procedure pour peupler la table des comptes ( creer un compte pour chaque personnel ) */
DELIMITER $

CREATE PROCEDURE IF NOT EXISTS p_peupler_comptes_utilisateurs()
BEGIN
    DECLARE v_id_personnel INT;
    DECLARE v_nom VARCHAR(255);
    DECLARE v_prenom VARCHAR(255);
    DECLARE v_nom_utilisateur VARCHAR(255);
    DECLARE v_mot_de_passe VARCHAR(255);
    DECLARE v_suffixe INT DEFAULT 1;
    DECLARE v_nom_utilisateur_unique BOOLEAN DEFAULT FALSE;
    DECLARE v_continuer BOOLEAN DEFAULT TRUE;

    DECLARE c_personnel CURSOR FOR
    SELECT id_personnel, nom, prenom
    FROM personnel;

    DECLARE CONTINUE HANDLER 
    FOR NOT FOUND
    SET v_continuer = FALSE;

    OPEN c_personnel;
    boucle_personnel: LOOP
        FETCH c_personnel 
        INTO v_id_personnel, v_nom, v_prenom;
        IF v_continuer = FALSE THEN
            LEAVE boucle_personnel;
        END IF;

        /* Générer un nom d'utilisateur unique */
        SET v_nom_utilisateur = CONCAT(LOWER(v_prenom), '.', LOWER(v_nom));
        SET v_nom_utilisateur_unique = FALSE;

        WHILE v_nom_utilisateur_unique = FALSE DO
            IF (SELECT COUNT(*) 
                FROM comptes_utilisateurs 
                WHERE nom_utilisateur = v_nom_utilisateur) = 0 THEN
                SET v_nom_utilisateur_unique = TRUE;
            ELSE
                SET v_nom_utilisateur = CONCAT(LOWER(v_prenom), '.', LOWER(v_nom), '.', v_suffixe);
                SET v_suffixe = v_suffixe + 1;
            END IF;
        END WHILE;

        /* Générer un mot de passe haché */
        SET v_mot_de_passe = f_generer_mot_de_passe(v_id_personnel);

        /* Insérer le compte utilisateur */
        INSERT INTO comptes_utilisateurs (id_personnel, nom_utilisateur, mot_de_passe)
        VALUES (v_id_personnel, v_nom_utilisateur, v_mot_de_passe);
    END LOOP;
    CLOSE c_personnel;
    /* afficher un message de succès */
    SELECT 'Les comptes utilisateurs ont été créés avec succès.' AS message;

    SELECT * FROM comptes_utilisateurs;
END$
DELIMITER ;

/* Test : */
CALL p_peupler_comptes_utilisateurs(); 

/* une procedure pour la prise de rendez-vous */
DELIMITER $
CREATE PROCEDURE p_prise_rendez_vous (
    IN in_prenom_patient VARCHAR(255),
    IN in_nom_patient VARCHAR(255),
    IN in_date_rendez_vous DATETIME,
    IN in_date_naissance DATE,
    IN in_adresse_patient VARCHAR(255),
    IN in_email_patient VARCHAR(255),
    IN in_numero_telephone VARCHAR(255),
    IN contact_urgence VARCHAR(255),
    IN in_assure_ou_pas BOOLEAN,
    IN in_specialite_consultation VARCHAR(255),
    OUT message VARCHAR(255)
)
BEGIN
    DECLARE v_id_patient INT;
    DECLARE v_id_personnel INT;
    DECLARE v_patient_existe BOOLEAN DEFAULT FALSE;

    /* Vérification du personnel disponible */
    BEGIN
        DECLARE EXIT HANDLER
        FOR NOT FOUND
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Aucun personnel disponible pour la consultation';

        SELECT id_personnel
        INTO v_id_personnel
        FROM personnel
        WHERE poste = 'Médecin'
        AND specialite = in_specialite_consultation
        AND f_verifier_disponibilite_personnel(id_personnel, in_date_rendez_vous) = TRUE
        ORDER BY RAND()
        LIMIT 1;
    END;

    /* Vérification de l'existence du patient */
    SELECT id_patient 
    INTO v_id_patient
    FROM patients
    WHERE email = in_email_patient;

    IF v_id_patient IS NOT NULL THEN
        SET v_patient_existe = TRUE;
    END IF;

    /* Si le patient n'existe pas, on l'ajoute */
    IF v_patient_existe = FALSE THEN
        INSERT INTO patients (nom, prenom, date_naissance, adresse, telephone, email, contact_urgence, assure)
        VALUES (in_nom_patient, in_prenom_patient, in_date_naissance, in_adresse_patient, in_numero_telephone, in_email_patient, contact_urgence, in_assure_ou_pas);
        SET v_id_patient = LAST_INSERT_ID();
    END IF;

    /* Affichage de message de confirmation */
    IF v_patient_existe = TRUE THEN
        SET message = CONCAT('Rendez-vous pris pour le patient déjà enregistré ', v_id_patient, ' avec le médecin ', v_id_personnel, ' le ', in_date_rendez_vous);
    ELSE
        SET message = CONCAT('Rendez-vous pris pour le nouveau patient ', v_id_patient, ' avec le médecin ', v_id_personnel, ' le ', in_date_rendez_vous);
    END IF;
END$
DELIMITER ;

/* Test : */
-- Prendre un rendez-vous pour un patient existant
CALL p_prise_rendez_vous(
    'Alice', 
    'Dupont', 
    '2024-12-28 10:00:00', 
    '1980-01-01', 
    '12 Rue de la Paix, Presqu\'île, Lyon', 
    'alice.dupont@gmail.com', 
    '0123456789',
    '0689123456', 
    TRUE, 
    'Cardiologie', 
    @message 
);

-- Afficher le message de sortie
SELECT @message;

-- Prendre un rendez-vous pour un nouveau patient
CALL p_prise_rendez_vous(
    'Rachid', 
    'Ghodbane', 
    '2024-12-29 14:30:00', 
    '1990-05-10', 
    '45 Rue de la Liberté, Monplaisir, Lyon', 
    'rachid.ghodbane@gmail.com', 
    '0712345678', 
    '0678123456', 
    FALSE, 
    'Cardiologie', 
    @message2 
);

-- Afficher le message de sortie
SELECT @message2; 

/* la procedure pour des statistiques sur les medecins */
DELIMITER $
CREATE PROCEDURE IF NOT EXISTS  p_statistiques_medecins()
BEGIN
    DECLARE v_id_medecin INT;
    DECLARE v_nom_medecin VARCHAR(255);
    DECLARE v_specialite VARCHAR(255);
    DECLARE v_années_experience INT;
    DECLARE v_recommendation VARCHAR(255);
    DECLARE v_continuer BOOLEAN DEFAULT TRUE;

    /* un curseur pour les medecins */
    DECLARE c_medecins CURSOR FOR
    SELECT id_personnel, nom, specialite, annees_experience
    FROM personnel
    WHERE poste = 'Médecin';

    BEGIN
        DECLARE CONTINUE HANDLER
        FOR NOT FOUND
        SET v_continuer = FALSE;

        /* Suppression de la table temporaire si elle existe */
        DROP TEMPORARY TABLE IF EXISTS medecins_statistiques;

        /* creation de la table temporaire */
        CREATE TEMPORARY TABLE  medecins_statistiques (
            id_personnel INT,
            nom VARCHAR(255),
            specialite VARCHAR(255),
            annees_experience INT,
            recommandation VARCHAR(255)
        );

        OPEN c_medecins;
        boucle_medecin : LOOP
            FETCH c_medecins
            INTO v_id_medecin, v_nom_medecin, v_specialite, v_années_experience;
            IF v_continuer = FALSE THEN
                LEAVE boucle_medecin;
            END IF;

            /* On recupere la recommandation */
            SET v_recommendation = f_recommandation(v_id_medecin);

            /* Insertion dans la table temporaire */
            INSERT INTO medecins_statistiques (id_personnel, nom, specialite, annees_experience, recommandation)
            VALUES (v_id_medecin, v_nom_medecin, v_specialite, v_années_experience, v_recommendation);
        END LOOP;
        CLOSE c_medecins;
    END;
    /* Affichage des resultats */
    SELECT * FROM medecins_statistiques;
END
$
DELIMITER ;

/* Test : */
CALL p_statistiques_medecins(); 

/* - une procedure pour affichage complexe ( details d'un patient ) */
/* -> on suppose que le patient peut faire plusieurs consultations, une seule admission, une seule intervention chirurgicale */
DELIMITER $
CREATE PROCEDURE IF NOT EXISTS p_details_patient(
    IN in_id_patient INT
)
BEGIN
    DECLARE v_nom_patient VARCHAR(255);
    DECLARE v_prenom_patient VARCHAR(255);
    DECLARE v_date_naissance DATE;
    DECLARE v_date_consultation DATETIME;
    DECLARE v_personnel_consultation VARCHAR(255);
    DECLARE v_motif_consultation TEXT;
    DECLARE v_date_admission DATE;
    DECLARE v_date_sortie DATE;
    DECLARE v_personnel_admission VARCHAR(255);
    DECLARE v_chambre_admission INT;
    DECLARE v_date_intervention DATETIME;
    DECLARE v_personnel_intervention VARCHAR(255);
    DECLARE v_taux_reussite DECIMAL(5, 2);
    DECLARE v_facture_patient DECIMAL(10, 2);
    DECLARE v_continuer BOOLEAN DEFAULT TRUE;

    DECLARE c_consultations CURSOR FOR
    SELECT date_consultation, id_personnel, motif_consultation
    FROM consultations
    WHERE id_patient = in_id_patient;

    /* On verifie si le patient existe */
    BEGIN
        DECLARE EXIT HANDLER
        FOR NOT FOUND
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Le patient n''existe pas';

        SELECT nom, prenom, date_naissance
        INTO v_nom_patient, v_prenom_patient, v_date_naissance
        FROM patients
        WHERE id_patient = in_id_patient;
    END;

    /* On recupere l'admission */
    SELECT date_admission, date_sortie, id_personnel, id_chambre
    INTO v_date_admission, v_date_sortie, v_personnel_admission, v_chambre_admission
    FROM admissions
    WHERE id_patient = in_id_patient;

    /* On recupere l'intervention chirurgicale */
    SELECT date_intervention, id_personnel, taux_reussite
    INTO v_date_intervention, v_personnel_intervention, v_taux_reussite
    FROM interventions_chirurgicales
    WHERE id_patient = in_id_patient;

    /* On recupere la facture -> on considere ici que la facture est unique
    et son montant est le total des consultations, admissions et interventions chirurgicales */
    SELECT f_calcul_facture(in_id_patient)
    INTO v_facture_patient;

    /* Affichage des informations -> bien structurer */
    SELECT CONCAT('Nom : ', v_nom_patient, ', Prenom : ', v_prenom_patient, ' , Date de naissance : ', v_date_naissance) AS patient;

    /* On recupere les consultations (une ou plusieures) */
    BEGIN
        DECLARE CONTINUE HANDLER
        FOR NOT FOUND
        SET v_continuer = FALSE;

        OPEN c_consultations;
        ma_boucle : LOOP
            FETCH c_consultations
            INTO v_date_consultation, v_personnel_consultation, v_motif_consultation;
            IF v_continuer = FALSE THEN
                LEAVE ma_boucle;
            END IF;
            SELECT CONCAT('Consultation le ', v_date_consultation, ' par ', v_personnel_consultation, ' avec comme motif ', v_motif_consultation) AS consultation;
        END LOOP;
        CLOSE c_consultations;
    END;

    IF v_date_admission IS NULL THEN
        SELECT CONCAT('PAS d''admission pour ce patient ') AS admission;
    ELSE
        SELECT CONCAT('Admission le :', v_date_admission, ' par ', v_personnel_admission, ' dans la chambre ', v_chambre_admission, ' avec une sortie prevue le : ', v_date_sortie) AS admission;
    END IF;

    IF v_date_intervention IS NULL THEN
        SELECT CONCAT('PAS d''intervention chirurgicale pour ce patient ') AS intervention;
    ELSE
        SELECT CONCAT('Intervention le ', v_date_intervention, ' par ', v_personnel_intervention, ' avec taux de reussite : ', v_taux_reussite) AS intervention;
    END IF;

    IF v_facture_patient IS NOT NULL THEN /* de toute facon il aura une facture a payer */
        SELECT CONCAT('Facture : ', v_facture_patient, ' , Statut : en attente') AS facture;
    END IF;
END$
DELIMITER ;

/* Test : */
CALL p_details_patient(2);
CALL p_details_patient(63); 

/* 4- Les event sous forme procedurales : */
/* la procedure pour archiver ( peupler historique medical)  */
DELIMITER $

CREATE PROCEDURE IF NOT EXISTS p_peuplement_historique_medical(
    IN in_date_limite DATETIME
)
BEGIN
    DECLARE v_id_patient INT;
    DECLARE v_date DATETIME; 
    DECLARE v_type_intervention ENUM('Intervention Chirurgicale', 'Consultation');
    DECLARE v_continuer BOOLEAN DEFAULT TRUE;

    /* curseur pour les consultations */
    DECLARE c_consultations CURSOR FOR
    SELECT id_patient, date_consultation
    FROM consultations
    WHERE date_consultation <= in_date_limite;

    /* curseur pour les interventions chirurgicales */
    DECLARE c_interventions CURSOR FOR
    SELECT id_patient, date_intervention
    FROM interventions_chirurgicales
    WHERE date_intervention <= in_date_limite;

    /* gestion des exceptions */
    IF in_date_limite > CURRENT_DATE THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Date limite invalide';
    END IF;
    /* Gestion des consultations */
    BEGIN
        DECLARE CONTINUE HANDLER
        FOR NOT FOUND
        SET v_continuer = FALSE;

        OPEN c_consultations;

        boucle_consultations : LOOP
            FETCH c_consultations
            INTO v_id_patient, v_date;
            IF v_continuer = FALSE THEN
                SET v_continuer = TRUE; /* reinitialisation de la variable pour la prochaine boucle */
                LEAVE boucle_consultations;
            END IF;

            /* Insertion dans l'historique medical pour les consultations */
            INSERT INTO historique_medical (id_patient, date, type_intervention)
            VALUES (v_id_patient, v_date, 'Consultation');
        END LOOP;

        CLOSE c_consultations;
    END;

    /* Gestion des interventions chirurgicales */
    BEGIN
        DECLARE CONTINUE HANDLER
        FOR NOT FOUND
        SET v_continuer = FALSE;

        OPEN c_interventions;

        boucle_interventions : LOOP
            FETCH c_interventions 
            INTO v_id_patient, v_date;
            IF v_continuer = FALSE THEN
                LEAVE boucle_interventions;
            END IF;

            /* Insertion dans l'historique medical pour les interventions chirurgicales */
            INSERT INTO historique_medical (id_patient, date, type_intervention)
            VALUES (v_id_patient, v_date, 'Intervention Chirurgicale');
        END LOOP;

        CLOSE c_interventions;
    END;

    SELECT * FROM historique_medical;
END $

DELIMITER ;

/* Test : */
CALL p_peuplement_historique_medical('2024-10-01 00:00:00'); 

/* la procedure pour sauvegarder */
DELIMITER $
CREATE PROCEDURE IF NOT EXISTS p_sauvegarde_base()
BEGIN
    DECLARE v_nom_fichier VARCHAR(255);
    DECLARE v_commande VARCHAR(255);
    DECLARE v_username VARCHAR(255);
    DECLARE v_nom_base VARCHAR(255);

    /* Définir les informations de connexion */
    SET v_username = 'votre_utilisateur'; /* Remplacez par votre nom d'utilisateur MySQL */
    SET v_nom_base = 'votre_base_de_donnees'; /* Remplacez par le nom de votre base de données */

    /* Définir le répertoire de sauvegarde */
    SET @repertoire_sauvegarde = '../sauvegarde/hopital/';

    /* Générer le nom du fichier de sauvegarde avec la date et l'heure */
    SET v_nom_fichier = CONCAT('sauvegarde_hopital_', DATE_FORMAT(NOW(), '%Y%m%d_%H%i%s'), '.sql');

    /* Générer la commande de sauvegarde */
    SET v_commande = CONCAT('mysqldump -u ', v_username, ' -p ', v_nom_base , ' > ', @repertoire_sauvegarde, v_nom_fichier);

    /* Afficher la commande de sauvegarde (pour vérification) */
    SELECT v_commande AS commande_sauvegarde;
END
$
DELIMITER ;

/* Test : */
CALL p_sauvegarde_base(); 

/* On peut bien sur automatiser la sauvegarde avec un script bash qui execute cette procedure ou un evenement qui declenche cette procedure */

/* la procédure pour générer un rapport */
DELIMITER $
CREATE PROCEDURE IF NOT EXISTS p_generer_rapport(
    in_date_debut DATE,
    in_date_fin DATE
)
BEGIN
    DECLARE v_nb_admissions INT;
    DECLARE v_nb_consultations INT;
    DECLARE v_nb_interventions INT;
    DECLARE v_duree_moyenne_admission DECIMAL(5, 2);
    DECLARE v_taux_occupation_chambres DECIMAL(5, 2);
    DECLARE v_taux_reussite_moyen_interventions DECIMAL(5, 2);
    DECLARE v_total_factures DECIMAL(10, 2);
    DECLARE v_nb_factures_impayees INT;
    DECLARE v_nb_factures_payees INT;

    /* Vérification des dates */
    IF in_date_debut > in_date_fin OR in_date_fin > CURRENT_DATE THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Dates invalides';
    END IF;

    /* Récupération du nombre d'admissions */
    SELECT COUNT(id_admission), AVG(DATEDIFF(date_sortie, date_admission))
    INTO v_nb_admissions, v_duree_moyenne_admission
    FROM admissions
    WHERE date_admission >= in_date_debut
    AND date_sortie <= in_date_fin;

    /* Récupération du nombre de consultations */
    SELECT COUNT(id_consultation)
    INTO v_nb_consultations
    FROM consultations
    WHERE date_consultation BETWEEN in_date_debut AND in_date_fin;

    /* Récupération du nombre d'interventions chirurgicales */
    SELECT COUNT(id_intervention), AVG(taux_reussite)
    INTO v_nb_interventions, v_taux_reussite_moyen_interventions
    FROM interventions_chirurgicales
    WHERE date_intervention BETWEEN in_date_debut AND in_date_fin;

    /* Récupération du taux d'occupation des chambres */
    SELECT f_taux_occupation_chambres()
    INTO v_taux_occupation_chambres;

    /* Récupération du total des factures */
    SELECT SUM(montant)
    INTO v_total_factures
    FROM facturation
    WHERE date_facture BETWEEN in_date_debut AND in_date_fin;

    /* Récupération du nombre de factures impayées */
    SELECT COUNT(id_facture)
    INTO v_nb_factures_impayees
    FROM facturation
    WHERE date_facture BETWEEN in_date_debut AND in_date_fin
    AND statut = 'en attente';

    /* Récupération du nombre de factures payées */
    SELECT COUNT(id_facture)
    INTO v_nb_factures_payees
    FROM facturation
    WHERE date_facture BETWEEN in_date_debut AND in_date_fin
    AND statut = 'payée';

    /* Affichage des résultats */
    SELECT CONCAT('Rapport du ', in_date_debut, ' au ', in_date_fin) AS Titre;
    SELECT CONCAT('Nombre d\'admissions : ', v_nb_admissions) AS Statistiques;
    SELECT CONCAT('Durée moyenne des admissions (jours) : ', v_duree_moyenne_admission) AS Statistiques;
    SELECT CONCAT('Nombre de consultations : ', v_nb_consultations) AS Statistiques;
    SELECT CONCAT('Nombre d\'interventions chirurgicales : ', v_nb_interventions) AS Statistiques;
    SELECT CONCAT('Taux d\'occupation des chambres : ', v_taux_occupation_chambres) AS Statistiques;
    SELECT CONCAT('Taux de réussite moyen des interventions chirurgicales : ', v_taux_reussite_moyen_interventions) AS Statistiques;
    SELECT CONCAT('Montant total des facturations : ', v_total_factures) AS Statistiques;
    SELECT CONCAT('Nombre de factures payées : ', v_nb_factures_payees) AS Statistiques;
    SELECT CONCAT('Nombre de factures en attente : ', v_nb_factures_impayees) AS Statistiques;
END$
DELIMITER ;

/* Test : */
CALL p_generer_rapport('2024-09-01', '2024-11-30'); 

/* Événement pour générer le rapport mensuel 
DELIMITER $
CREATE EVENT IF NOT EXISTS e_generer_rapport
ON SCHEDULE
    EVERY 1 MONTH
    STARTS (LAST_DAY(CURRENT_DATE) + INTERVAL 1 DAY - INTERVAL 1 MONTH + INTERVAL 23 HOUR + INTERVAL 59 MINUTE)
DO
CALL p_generer_rapport(LAST_DAY(CURRENT_DATE - INTERVAL 1 MONTH) + INTERVAL 1 DAY, LAST_DAY(CURRENT_DATE));
$
DELIMITER ;
*/