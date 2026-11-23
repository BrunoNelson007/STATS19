/*comparison by speed band*/
SELECT
    CASE WHEN light_conditions = 6 THEN 'darkness - no lighting'
        WHEN light_conditions = 1 THEN 'daylight'
    END AS light_group,
    CASE WHEN speed_limit IN (20, 30) THEN '20 to 30MPH' 
        WHEN speed_limit IN (40, 50) THEN '40 to 50MPH'
        WHEN speed_limit IN (60, 70) THEN '60 to national speed limit'
    END AS speed_band,
    /*CASE WHEN urban_or_rural_area = 1 THEN 'urban' 
        WHEN urban_or_rural_area = 2 THEN 'rural'
        WHEN urban_or_rural_area = 3 THEN 'unallocated'
        END AS type_of_road,*/
    COUNT(*) as collisions,
    SUM(CASE WHEN collision_severity IN (1, 2) THEN 1 ELSE 0 END) AS fatal_or_serious,
    ROUND(100.0 * SUM(CASE WHEN collision_severity IN (1, 2) THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_fatal_or_serious
    FROM collision
    WHERE light_conditions IN (1, 6) AND urban_or_rural_area = 2
    GROUP BY light_group, speed_band
    ORDER BY speed_band, light_group;

	
	/* daylight vs unlit on rural and urban roads */
SELECT
    CASE WHEN light_conditions = 6 THEN 'darkness - no lighting'
        WHEN light_conditions = 1 THEN 'daylight'
    END AS light_group,
    CASE WHEN urban_or_rural_area = 1 THEN 'urban' 
        WHEN urban_or_rural_area = 2 THEN 'rural'
        WHEN urban_or_rural_area = 3 THEN 'unallocated'
        END AS type_of_road,
    COUNT(*) as collisions,
    SUM(CASE WHEN collision_severity IN (1, 2) THEN 1 ELSE 0 END) AS fatal_or_serious,
    ROUND(100.0 * SUM(CASE WHEN collision_severity IN (1, 2) THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_fatal_or_serious
    FROM collision
    WHERE light_conditions IN (1, 6)
    GROUP BY light_group, type_of_road
    ORDER BY type_of_road, light_group;
	

	/* percentage of fatal or serious collisions under daylight vs darkness */
SELECT
    CASE WHEN light_conditions IN (4, 5, 6, 7) THEN 'darkness'
        WHEN light_conditions = 1 THEN 'daylight'
    END AS light_group,
    COUNT(*) as collisions,
    SUM(CASE WHEN collision_severity IN (1, 2) THEN 1 ELSE 0 END) AS fatal_or_serious,
    ROUND(100.0 * SUM(CASE WHEN collision_severity IN (1, 2) THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_fatal_or_serious
    FROM collision
    WHERE light_conditions IN (1, 4, 5, 6, 7)
    GROUP BY light_group;