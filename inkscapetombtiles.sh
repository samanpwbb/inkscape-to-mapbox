#!/bin/bash
# Originally written by Young Hahn / https://github.com/yhahn
# Expects a batch export from Inkscape of tiles in the current directory.

echo "
CREATE TABLE images (
    tile_data blob,
    tile_id text
);
CREATE TABLE map (
   zoom_level INTEGER,
   tile_column INTEGER,
   tile_row INTEGER,
   tile_id TEXT,
   grid_id TEXT
);
CREATE TABLE metadata (
    name text,
    value text
);
CREATE VIEW tiles AS
    SELECT
        map.zoom_level AS zoom_level,
        map.tile_column AS tile_column,
        map.tile_row AS tile_row,
        images.tile_data AS tile_data
    FROM map
    JOIN images ON images.tile_id = map.tile_id;
CREATE UNIQUE INDEX images_id ON images (tile_id);
CREATE UNIQUE INDEX map_index ON map (zoom_level, tile_column, tile_row);
CREATE UNIQUE INDEX name ON metadata (name);
INSERT INTO metadata VALUES('name', 'MapBox Infrastructure');
INSERT INTO metadata VALUES('description', 'MapBox datacenters and edge servers.');
INSERT INTO metadata VALUES('minzoom', '2');
INSERT INTO metadata VALUES('maxzoom', '2');
INSERT INTO metadata VALUES('center', '0,0,2');
INSERT INTO metadata VALUES('bounds', '-180,-85.051,180,85.051');
" | sqlite3 scalemap.mbtiles

for file in `ls ?-?.png`; do
  echo $file | sed "s/\([^-]*\)-\([^-\.]*\).png/INSERT OR REPLACE INTO map VALUES(2,\1,\2,'\1-\2.png','');/" | sqlite3 scalemap.mbtiles
  echo "INSERT INTO images VALUES(X'`hexdump -ve '1/1 "%.2x"' $file`', '$file');" | sqlite3 scalemap.mbtiles
  rm $file
done
