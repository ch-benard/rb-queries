SELECT
	TO_CHAR(s.updated_at, 'DD/MM/YYYY hh:mm:ss') AS "Date de dernière mise à jour",
	comments."Nombre de commentaires",
	"Nombre d'acteurs",
	"Nombre de dispositifs",
	-- Conditions d'accès à l'eau
	CONCAT(
	--access_to_water
	CASE  access_to_water
	WHEN TRUE THEN CONCAT('Accès à l''eau', CHR(13),CHR(10))
	WHEN FALSE THEN CONCAT('Pas d''accès à l''eau', CHR(13),CHR(10))
	ELSE CONCAT('Accès à l''eau non renseigné', CHR(13),CHR(10))
	END,
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
	) AS "Conditions d''accès à l''eau"
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
WHERE
	s.resorption_target = '2021'
