SELECT
	c.name AS "Commune",
	d.name AS "Département",
	s.shantytown_id AS "Identifiant",
	CASE 
	WHEN s."name" IS NOT NULL THEN s."name"
	ELSE s."address"
	END AS "Nom du site",
	s.population_total AS "Population totale",
	soc."label" AS "Origine des ressortissants",
	TO_CHAR(s.updated_at, 'DD/MM/YYYY hh:mm:ss') AS "Date de dernière mise à jour",
	TO_CHAR(s.closed_at, 'DD/MM/YYYY') AS "Date de fermeture du site",	
	comments."Nombre de commentaires",
	"Nombre d'acteurs",
	"Nombre de dispositifs",
	-- Conditions d'accès à l'eau
	CASE access_to_water
	WHEN TRUE
	THEN
		CASE
		WHEN 
			s.water_potable IS NULL OR s.water_potable = FALSE OR
			s.water_continuous_access IS NULL OR s.water_continuous_access = FALSE OR
            s.water_public_point IS NULL OR s.water_public_point = FALSE OR
            s.water_distance IS NULL OR s.water_distance != '0-20' OR
            s.water_roads_to_cross IS NULL OR s.water_roads_to_cross = TRUE OR
            s.water_everyone_has_access IS NULL OR s.water_everyone_has_access = FALSE OR
            s.water_stagnant_water IS NULL OR s.water_stagnant_water = TRUE OR
            s.water_hand_wash_access IS NULL OR s.water_hand_wash_access = FALSE OR
            COALESCE(s.population_total, 0) / COALESCE(s.water_hand_wash_access_number, 1) < 20
        THEN
        	'A améliorer'
        ELSE
        	'Oui'
        END
    WHEN FALSE
    THEN
    	'Non'
	ELSE
		'Inconnu'
	END
	AS "Accès à l'eau",
	CONCAT(
	-- water_potable
	CASE water_potable
	WHEN TRUE THEN CONCAT('Eau potable', CHR(13),CHR(10))
	WHEN FALSE THEN CONCAT('non potable', CHR(13),CHR(10))
	ELSE NULL
	END,
	-- water_continuous_access
	CASE water_continuous_access
	WHEN TRUE THEN CONCAT('Accès continu', CHR(13),CHR(10))
	ELSE NULL
	END,
	-- water_public_point
	CASE water_public_point
	WHEN TRUE THEN CONCAT('Point d''accès public', CHR(13),CHR(10))
	ELSE NULL
	END,
	-- water_distance
	CASE water_distance
	WHEN '0-20' THEN CONCAT('Accès à moins de 20m', CHR(13),CHR(10)) 
	WHEN '20-50' THEN CONCAT('Accès de 20m à 50m', CHR(13),CHR(10))
	WHEN '50-100' THEN CONCAT('Accès de 50m à 100m', CHR(13),CHR(10))
	WHEN '100+' THEN CONCAT('Accès à plus de 100m', CHR(13),CHR(10))
	ELSE NULL
	END,
	-- water_roads_to_cross
	CASE water_roads_to_cross
	WHEN TRUE THEN CONCAT('Route à traverser', CHR(13),CHR(10))
	ELSE NULL
	END,
	-- water_everyone_has_access
	CASE water_everyone_has_access
	WHEN TRUE THEN CONCAT('Accès à l''eau pour tous',  CHR(13),CHR(10))
	ELSE NULL
	END,
	-- water_stagnant_water
	CASE water_stagnant_water
	WHEN TRUE THEN CONCAT('Eaux stagnantes autour du point de distribution',  CHR(13),CHR(10))
	WHEN FALSE THEN CONCAT('Pas d’eaux stagnantes autour du point de distribution',  CHR(13),CHR(10))
	ELSE NULL
	END,
	-- water_hand_wash_access
	CASE water_hand_wash_access
	WHEN TRUE THEN CONCAT('Bac de lavage des mains',  CHR(13),CHR(10))
	ELSE NULL
	END,
	CASE 
	WHEN population_total > 0
	THEN
		CASE 
		WHEN water_hand_wash_access_number > 0
		THEN
			CASE 
			WHEN water_hand_wash_access_number > population_total 
			THEN CONCAT('Plus d''1 bac de lavage par personne',  CHR(13),CHR(10))
			ELSE
				CONCAT('1 bac de lavage de mains pour ', COALESCE(population_total, 0) / COALESCE(water_hand_wash_access_number, 1), CHR(13),CHR(10))
			END
		ELSE NULL
		END
	ELSE
		NULL
	END
	) AS "Conditions d'accès à l'eau",
	-- Accès aux toilettes
	CASE access_to_sanitary
	WHEN TRUE
	THEN
		CASE
		WHEN 
			s.sanitary_insalubrious IS NULL OR s.sanitary_insalubrious = TRUE OR
			s.sanitary_on_site IS NULL OR s.sanitary_on_site = FALSE OR
            COALESCE(s.population_total, 0) / COALESCE(s.sanitary_number, 1) < 20
        THEN
        	'A améliorer'
        ELSE
        	'Oui'
        END
    WHEN FALSE
    THEN
    	'Non'
	ELSE
		'Inconnu'
	END
	AS "Accès aux toilettes",
	-- Conditions d'accès aux toilettes
	CONCAT(
	-- toilettes insalubres
	CASE sanitary_insalubrious
	WHEN TRUE THEN CONCAT('Marques de défécation à l''air libre', CHR(13),CHR(10))
	WHEN FALSE THEN CONCAT('Pas de marques de défécation à l''air libre  ', CHR(13),CHR(10))
	ELSE NULL
	END,
	-- sanitary_on_site
	CASE sanitary_on_site
	WHEN TRUE THEN CONCAT('Accès aux toilettes sur site', CHR(13),CHR(10))
	WHEN FALSE THEN CONCAT('Pas d''accès aux toilettes sur site', CHR(13),CHR(10))
	ELSE NULL
	END,
	-- sanitory_access_ratio
	CASE
	WHEN population_total > 0
	THEN
		CASE access_to_sanitary
		WHEN TRUE 
		THEN 
			CASE 
			WHEN sanitary_number > 0
			THEN
				CASE 
				WHEN sanitary_number > population_total 
				THEN CONCAT('Plus d''1 toilette par personne',  CHR(13),CHR(10))
				ELSE
					CONCAT('1 toilette pour ', population_total / sanitary_number, CHR(13),CHR(10))
				END
			ELSE NULL
			END
		ELSE
			NULL
		END
	ELSE
		NULL
	END
	) AS "Conditions d'accès aux toilettes",
	-- Evacuation des déchets
	CASE trash_evacuation
	WHEN TRUE
	THEN
		CASE
		WHEN 
			s.trash_cans_on_site IS NULL OR s.trash_cans_on_site < 1 OR
			s.trash_evacuation_regular IS NULL OR s.trash_evacuation_regular = FALSE OR
			s.trash_accumulation IS NULL OR s.trash_accumulation = TRUE
        THEN
        	'A améliorer'
        ELSE
        	'Oui'
        END
    WHEN FALSE
    THEN
    	'Non'
	ELSE
		'Inconnu'
	END
	AS "Evacuation des déchets",
	-- Conditions d'évacuations des déchets
	CONCAT(
	-- trash_cans_on_site
	CASE
	WHEN trash_cans_on_site > 0
	THEN CONCAT(trash_cans_on_site, ' poubelle(s) / benne(s) à proximité immédiate du site (moins de 100 mètres)', CHR(13),CHR(10))
	ELSE NULL
	END,
	-- trash_acumulation
	CASE trash_accumulation
	WHEN TRUE
	THEN CONCAT('Accumulation de déchets sur le site ou aux abords', CHR(13),CHR(10))
	WHEN FALSE
	THEN CONCAT('Pas d''accumulation de déchets sur le site ou aux abords', CHR(13),CHR(10))
	ELSE NULL
	END,
	-- trash_evacuation_regular
	CASE trash_evacuation_regular
	WHEN TRUE
	THEN CONCAT('Collecte régulière des poubelles / bennes.', CHR(13),CHR(10))
	WHEN FALSE
	THEN CONCAT('Pas de collecte régulière des poubelles / bennes.', CHR(13),CHR(10))
	ELSE NULL
	END
	) AS "Conditions d'évacuations des déchets",
	-- Accès à l'électricité
	CONCAT(
	CASE fk_electricity_type
	WHEN 3 THEN 'Oui'
	WHEN 2 THEN 'Non'
	WHEN 1 THEN 'Inconnu'
	ELSE NULL
	END
	) AS "Accès à l'électricité",
	-- Présence de nuisible
	CASE vermin
	WHEN TRUE THEN 'Oui'
	WHEN FALSE THEN 'Non'
	ELSE 'Inconnu'
	END AS "Présence de nuisibles",
	CASE
	WHEN vermin_comments IS NOT NULL THEN vermin_comments
	ELSE NULL
	END AS "Détail présence de nuisibles",
	-- Prévention incendie
	CASE fire_prevention_measures
	WHEN TRUE THEN 'Oui'
	WHEN FALSE THEN 'Non'
	ELSE 'Inconnu'
	END AS "Prévention incendie",
	-- Détail prévention incendie
	CASE 
	WHEN fire_prevention_comments IS NOT NULL
	THEN fire_prevention_comments
	ELSE NULL
	END
	AS "Mesures de prévention incendie",
	-- Objectif résorption
	s.resorption_target AS "Objectif résorption"
FROM
	shantytowns s
LEFT JOIN
	-- Nombres de commentaires
	(
	SELECT
		sc.fk_shantytown AS "shantytown_id",
		COUNT(*) AS "Nombre de commentaires"
	FROM
		shantytown_comments sc 
	GROUP BY
		sc.fk_shantytown
	) AS comments ON comments.shantytown_id = s.shantytown_id 
LEFT JOIN
	-- Nombre d'acteurs
	(
	SELECT
		sa.fk_shantytown AS "shantytown_id",
		COUNT(*) AS "Nombre d'acteurs"
	FROM
		shantytown_actors sa 
	GROUP BY
		sa.fk_shantytown
	) AS actors ON actors.shantytown_id = s.shantytown_id
LEFT JOIN
	-- Nombre de dispositifs
	(
	SELECT
		ps.fk_shantytown AS "shantytown_id",
		COUNT(*) AS "Nombre de dispositifs"
	FROM
		plan_shantytowns ps
	LEFT JOIN
		plans2 p2 ON p2.plan_id = ps.fk_plan
	WHERE
		p2.expected_to_end_at >= now()
	GROUP BY
		ps.fk_shantytown
	) AS dispositifs ON dispositifs.shantytown_id = s.shantytown_id
LEFT JOIN
	-- Ville (cities)
	cities c ON c.code =s.fk_city
LEFT JOIN
	-- Département
	departements d ON d.code = c.fk_departement
LEFT JOIN
	-- Origine des ressortissants
	shantytown_origins so ON so.fk_shantytown = s.shantytown_id
LEFT JOIN
	-- Libellé de l'origine des ressortissants
	social_origins soc ON soc.social_origin_id = so.fk_social_origin
WHERE
	-- uniquement resortissants européens
	so.fk_social_origin = 2
ORDER BY
	d.name, c.name, s.shantytown_id
