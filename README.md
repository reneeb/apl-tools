# Image Tools

This is a collection of utility scripts that helps to handle image data.

## find\_images.pl

This script searches for images in a given path and stores meta information in a SQLite database.
That way it is very easy to further process those information. The database table has these
columns:

  * filename
  * path (PRIMARY KEY)
  * sha256
  * model (of the device that was used to take the photo)
  * vendor (of the mentioned device)
  * create\_inode
  * create\_orig
  * gps\_position (GPS position, lat/lon combined)
  * gps\_latitude (GPS position -- latitude)
  * gps\_longitude (GPS position -- longitude)
  * gps\_position\_dec (GPS position, lat/lon combined - decimal format)
  * gps\_latitude\_dec (GPS position -- latitude - decimal format)
  * gps\_longitude\_dec (GPS position -- longitude - decimal format)
  * gps\_time

If GPS information is found in EXIF data, then the original info is stored (which is stored
in *xx deg xx' xx" N* format) and in decimal format. The decimal format is necessary for the
files that are imported into Google Earth et al.

### Usage

```
perl find_images.pl --path /path/ --mime-type video
```

### Options

  * path
    This directory is searched for images (default: .)
  * db
    Path/name of the SQLite database that is created (default: ./images.db)
  * mime-type
    The files need to have this MIME type (default: image/)

## create\_kml.pl

Creates a [KML](https://en.wikipedia.org/wiki/Keyhole_Markup_Language) file that can be imported into
Google Earth et al. to show a pathway.

### Usage

```
perl create_kml.pl 
```

### Options

  * kml
    Path/name of the KML file to be created (default: ./images.kml)
  * db
    Path/name of the SQLite database that is created (default: ./images.db)
  * start
    Start date (uses the value of gps_time)
  * end
    End date (uses the value of gps_time)

## Other use cases

### Collect meta data for videos

```
perl find_images.pl --path /path/ --mime-type video
```

### Get only JPG images

```
perl find_images.pl --path /path/ --mime-type image/jpg
```

### Create CSV of all used camera models

```
sqlite3 -header -csv image.db "SELECT DISTINCT vendor, model FROM image_data WHERE vendor IS NOT NULL" > camera.csv
```

### Create CSV with all GPS information for photos taken in 2020

```
sqlite3 -header -csv image.db "SELECT filename, gps_longitude_dec, gps_latitude_dec FROM image_data WHERE gps_longitude_dec IS NOT NULL AND create_time BETWEEN('2020-01-01 00:00:00', '2020-12-31 23:59:59')" > gps_data.csv
```

### Create KML file for photos taken in 2020

```
perl create_kml.pl --start "2020-01-01 00:00:00" --end "2020-12-31 23:59:59"
```
