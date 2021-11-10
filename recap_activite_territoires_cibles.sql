SELECT
	COUNT(t.closedShantytowns) AS "Sites fermés/résorbés",
	COUNT(t.newShantytowns) AS "Sites ouverts",
	COUNT(t.shantytownsWithComments) AS "Sites avec commentaires",
	COUNT(t.shantytownHistories) AS "Sites mis à jour",
	SUM(t.pourcentage_of_completion) AS "Pourcentage de complétion",
	array_to_string(array_agg(DISTINCT t.closedShantytowns), ',') AS "Identifiants des sites fermés/résorbés",
    array_to_string(array_agg(DISTINCT t.newShantytowns), ',') AS "Identifiants des sites ouverts",
	array_to_string(array_agg(DISTINCT t.shantytownsWithComments), ',') AS "Identifiants des sites avec commentaires",
	array_to_string(array_agg(DISTINCT t.shantytownHistories), ',') AS "Identifiants des sites mis à jour",
	fk_departement AS "Département"
FROM
(
    -- Retrieve new shantytowns
    SELECT
        CAST(NULL AS bigint) AS closedShantytowns,
        shantytown_id AS newShantytowns,
        CAST(NULL AS bigint) AS shantytownsWithComments,
        CAST(NULL AS bigint) AS shantytownHistories,
        NULL AS comment,
        CAST(NULL AS bigint) AS pourcentage_of_completion,
        fk_departement
    FROM
        shantytowns
    LEFT JOIN cities AS city ON shantytowns.fk_city = city.code
    WHERE
    	shantytowns.created_at >= '2021-10-25'
    AND
    	shantytowns.created_at <= '2021-10-30'
UNION
    -- Retrieve closed shantytowns
    SELECT
        shantytown_id AS closedShantytowns,
        CAST(NULL AS bigint) AS newShantytowns,
        CAST(NULL AS bigint) AS shantytownsWithComments,
        CAST(NULL AS bigint) AS shantytownHistories,
        NULL AS comment,
        CAST(NULL AS bigint) AS pourcentage_of_completion,
        fk_departement
    FROM
    	shantytowns
    LEFT JOIN cities AS city ON shantytowns.fk_city = city.code
    WHERE
    	(shantytowns.closed_at >= '2021-10-25' AND shantytowns.closed_at <= '2021-10-30')
    OR
    	(shantytowns.updated_at >= '2021-10-25' AND shantytowns.closed_at IS NOT NULL)
UNION
    -- Retrieve shantytowns with public or covid comments
    SELECT
        CAST(NULL AS bigint) AS closedShantytowns,
        CAST(NULL AS bigint) AS newShantytowns,
        shantytowns.shantytown_id AS shantytownsWithComments,
        CAST(NULL AS bigint) AS shantytownHistories,
        shantytown_comments.description AS comment,
        CAST(NULL AS bigint) AS pourcentage_of_completion,
        fk_departement
    FROM
    	shantytown_comments
    LEFT JOIN shantytowns ON shantytown_comments.fk_shantytown = shantytowns.shantytown_id
    LEFT JOIN cities AS city ON shantytowns.fk_city = city.code
    WHERE
    	shantytown_comments.created_at >= '2021-10-25'
    AND
    	shantytown_comments.created_at < '2021-10-30'
    AND
    	(
    		shantytown_comments.private IS FALSE
        OR
        	shantytown_comments.shantytown_comment_id IN (SELECT fk_comment FROM shantytown_covid_comments)
    	)
UNION
    -- Retrieve shantytowns updates and exclude creation/close
    SELECT
        CAST(NULL AS bigint) AS closedShantytowns,
        CAST(NULL AS bigint) AS newShantytowns,
        CAST(NULL AS bigint) shantytownsWithComments,
        shantytown_id AS shantytownHistories,
        NULL AS comment,
        CAST(NULL AS bigint) AS pourcentage_of_completion,
        fk_departement
    FROM
    	"ShantytownHistories"
    LEFT JOIN cities AS city ON "ShantytownHistories".fk_city = city.code
    WHERE
    	"ShantytownHistories".updated_at >= '2021-10-25'
    AND
    	"ShantytownHistories".updated_at < '2021-10-30'
    AND
    	"ShantytownHistories".updated_at != "ShantytownHistories".created_at
    AND
    	"ShantytownHistories".closed_at IS NULL
UNION
	-- Retrieves completion % of open shantytowns
	SELECT
        CAST(NULL AS bigint) AS closedShantytowns,
        CAST(NULL AS bigint) AS newShantytowns,
        CAST(NULL AS bigint) shantytownsWithComments,
        CAST(NULL AS bigint) AS shantytownHistories,
        NULL AS comment,
	    AVG(tmp.pourcentage_completion),
		tmp.departement_id as "departement_id"
	FROM
	    (SELECT
	        c.fk_departement as "departement_id",
	        ((CASE WHEN (SELECT regexp_matches(s.address, '^(.+) [0-9]+ [^,]+,? [0-9]+,? [^, ]+(,.+)?$'))[1] IS NOT NULL THEN 1 ELSE 0 END)
	        +
	        (CASE WHEN ft.label <> 'Inconnu' THEN 1 ELSE 0 END)
	        +
	        (CASE WHEN ot.label <> 'Inconnu' THEN 1 ELSE 0 END)
	        +
	        (CASE WHEN s.census_status IS NOT NULL THEN 1 ELSE 0 END)
	        +
	        (CASE WHEN s.population_total IS NOT NULL THEN 1 ELSE 0 END)
	        +
	        (CASE WHEN s.population_couples IS NOT NULL THEN 1 ELSE 0 END)
	        +
	        (CASE WHEN s.population_minors IS NOT NULL THEN 1 ELSE 0 END)
	        +
	        (CASE WHEN s.population_total IS NOT NULL AND s.population_total >= 10 AND (SELECT COUNT(*) FROM shantytown_origins WHERE fk_shantytown = s.shantytown_id) > 0 THEN 1 ELSE 0 END)
	        +
	        (CASE WHEN et.label <> 'Inconnu' THEN 1 ELSE 0 END)
	        +
	        (CASE WHEN s.access_to_water IS NOT NULL THEN 1 ELSE 0 END)
	        +
	        (CASE WHEN s.access_to_sanitary IS NOT NULL THEN 1 ELSE 0 END)
	        +
	        (CASE WHEN s.trash_evacuation IS NOT NULL THEN 1 ELSE 0 END))::FLOAT / 12.0 AS pourcentage_completion
	    FROM
	        shantytowns s
	    LEFT JOIN
	        cities c ON s.fk_city = c.code
	    LEFT JOIN
	        field_types ft ON s.fk_field_type = ft.field_type_id
	    LEFT JOIN
	        owner_types ot ON s.fk_owner_type = ot.owner_type_id
	    LEFT JOIN
	        electricity_types et ON s.fk_electricity_type = et.electricity_type_id
	    WHERE
			s.closed_at IS NULL
		) AS tmp
	GROUP BY
		departement_id
) AS t
WHERE 
	t.fk_departement IN ('13', '34', '44', '49', '59', '69', '94')
GROUP BY 
	t.fk_departement
ORDER BY
	t.fk_departement ASC ;
