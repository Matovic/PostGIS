-- 2.
SELECT name, ST_AsText(ST_TRANSFORM(way, 4326)::geography)
FROM public.planet_osm_polygon WHERE admin_level = '4';

-- pre zobrazenie mapy kliknut na Geometry Viewer pre way
SELECT way FROM public.planet_osm_polygon WHERE admin_level = '4'; 

-- 3.
SELECT name, ST_AREA(ST_TRANSFORM(way, 4326)::geography)/POWER(1000, 2) AS size
FROM public.planet_osm_polygon WHERE admin_level = '4'
ORDER BY size;

-- 4.						  
-- nájdenie súradnicového systému pre stĺpec way
SELECT DISTINCT ST_SRID(way) FROM planet_osm_polygon; -- 3857

-- vymazanie vloženého domu
DELETE FROM planet_osm_polygon
WHERE name='Home';

-- vloženie domu
INSERT INTO planet_osm_polygon("addr:housename", "addr:housenumber", building, name, z_order, way) 
VALUES(
	'Spartakovská', '9', 'yes', 'Home', 0, ST_TRANSFORM(ST_PolygonFromText(
	'POLYGON((17.59864 48.37502, 17.59870 48.37483, 17.59895 48.37486, 
	17.59888 48.37506, 17.59864 48.37502))', 4326), 3857)
);
-- zobrazenie výsledku
SELECT * FROM planet_osm_polygon WHERE name='Home';

-- 5.
SELECT name
FROM planet_osm_polygon
WHERE admin_level = '4' AND ST_INTERSECTS(
	way,
	(SELECT way
	FROM planet_osm_polygon
	WHERE name='Home')
);

--  6.
-- nájdenie súradnicového systému pre stĺpec way
SELECT DISTINCT ST_SRID(way) FROM planet_osm_point; -- 3857

-- vymazanie vloženého domu
DELETE FROM planet_osm_point
WHERE name='location';

-- vloženie polohy
INSERT INTO planet_osm_point("addr:housename", "addr:housenumber", building, name, z_order, way) 
VALUES(
	'Spartakovská', '9', 'yes', 'location', 0, 
	ST_TRANSFORM(ST_SetSRID(ST_MakePoint(17.5988032, 48.3749505), 4326), 3857)
);

-- zobrazenie výsledku
SELECT * FROM planet_osm_point WHERE name='location';

-- 7.
SELECT name
FROM planet_osm_polygon
WHERE name='Home' AND ST_INTERSECTS(
	way,
	(SELECT way
	FROM planet_osm_point
	WHERE name='location')
);

-- 8.
SELECT ST_Distance(ST_TRANSFORM(ST_TRANSFORM(polygon.way, 4326), 5514), 
				   ST_TRANSFORM(ST_TRANSFORM(point.way, 4326), 5514))/1000 AS distance
FROM planet_osm_polygon polygon, planet_osm_point point
WHERE 
	polygon.name='Fakulta informatiky a informačných technológií STU' AND 
	point.name='location';

SELECT ST_Distance(ST_TRANSFORM(polygon.way, 4326)::geography, 
				   ST_TRANSFORM(point.way, 4326)::geography)/1000 AS distance
FROM planet_osm_polygon polygon, planet_osm_point point
WHERE 
	polygon.name='Fakulta informatiky a informačných technológií STU' AND 
	point.name='location';

-- 10.
-- použijeme SK% lebo hladama slovenske okresy
SELECT ST_AsText(ST_TRANSFORM(ST_Centroid(
	(SELECT way	FROM public.planet_osm_polygon 
	WHERE admin_level = '8' AND ref LIKE 'SK%'
	ORDER BY ST_AREA(ST_TRANSFORM(way, 4326)::geography) 
	LIMIT 1)), 4326)::geography
);

-- query pre zistenie ID pre zobrazenie najmensieho okresu v QGIS
SELECT * FROM public.planet_osm_polygon 
WHERE admin_level = '8' AND ref LIKE 'SK%'
ORDER BY ST_AREA(ST_TRANSFORM(way, 4326)::geography)
LIMIT 1

-- 11.
-- nájdenie súradnicového systému pre stĺpec way
SELECT DISTINCT ST_SRID(way) FROM planet_osm_roads; -- 3857

CREATE TABLE task11_new AS(
	SELECT road.way
	FROM public.planet_osm_line road
	JOIN public.planet_osm_polygon polygon
	ON ST_Distance(ST_TRANSFORM(road.way, 4326)::geography,
				   ST_TRANSFORM(polygon.way, 4326)::geography) < 10000
	WHERE
		road.highway IN ('trunk', 'secondary', 'trunk_link', 'secondary_link', 'primary', 'residential', 
						 'primary_link', 'motorway_link', 'motorway', 'service', 'track') AND 
		polygon.name IN ('okres Malacky', 'okres Pezinok') AND
		NOT ST_Contains(ST_TRANSFORM(road.way, 4326)::geometry, 
					   ST_TRANSFORM(polygon.way, 4326)::geometry)); 

-- 12.
-- nájdenie súradnicového systému pre stĺpec shape
SELECT DISTINCT ST_SRID(shape) FROM katastralne_uzemie; -- 5514

SELECT * FROM katastralne_uzemie AS kataster
WHERE ST_INTERSECTS(ST_TRANSFORM(kataster.shape, 4326)::geography,
	(SELECT ST_TRANSFORM(road.way, 4326)::geography
	FROM public.planet_osm_line road
	JOIN public.planet_osm_polygon polygon
	ON ST_Contains(ST_TRANSFORM(polygon.way, 4326)::geometry, ST_TRANSFORM(road.way, 4326)::geometry)
	WHERE
	 	polygon.name='okres Trnava' AND
		road.highway IN ('trunk', 'secondary', 'trunk_link', 'secondary_link', 'primary', 'residential', 
							 'primary_link', 'motorway_link', 'motorway', 'service', 'track')
	ORDER BY ST_Length(ST_TRANSFORM(road.way, 4326)::geography) DESC
	LIMIT 1)
);

-- pre zobrazenie na mape najdeme id
SELECT *
FROM public.planet_osm_line road
JOIN public.planet_osm_polygon polygon
ON ST_Contains(ST_TRANSFORM(polygon.way, 4326)::geometry, ST_TRANSFORM(road.way, 4326)::geometry)
WHERE
	polygon.name='okres Trnava' AND
	road.highway IN ('trunk', 'secondary', 'trunk_link', 'secondary_link', 'primary', 'residential', 
						 'primary_link', 'motorway_link', 'motorway', 'service', 'track')
ORDER BY ST_Length(ST_TRANSFORM(road.way, 4326)::geography) DESC
LIMIT 1
					
-- 13.
SELECT ST_AREA(ST_TRANSFORM(ST_UNION(way), 4326)::geography)/POWER(1000, 2) AS oblast_vymera
FROM public.planet_osm_polygon
WHERE 
	ref LIKE 'SK%' AND admin_level='8' AND name NOT LIKE 'okres Bratislava %' AND
	ST_DISTANCE(ST_TRANSFORM(way, 4326)::geography, ST_TRANSFORM(
		(SELECT ST_Union(way) 
		FROM public.planet_osm_polygon 
		WHERE name LIKE 'okres Bratislava %'), 
		4326)::geography) < 20000

--pre mapu
CREATE TABLE task13 AS(
	SELECT *
	FROM public.planet_osm_polygon
	WHERE
		ref LIKE 'SK%' AND admin_level='8' AND name NOT LIKE 'okres Bratislava %' AND
		ST_DISTANCE(ST_TRANSFORM(way, 4326)::geography, ST_TRANSFORM(
			(SELECT ST_Union(way) 
			FROM public.planet_osm_polygon 
			WHERE name LIKE 'okres Bratislava %'), 
			432DROP TABLE task116)::geography) < 20000
);

DROP TABLE task11, task13;