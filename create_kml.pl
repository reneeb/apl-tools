#!/usr/bin/perl

use v5.24;

use Carp;
use Data::Printer;
use DBI;
use Getopt::Long;
use XML::LibXML;

use experimental 'signatures';

our $VERSION = '1.0.0';

GetOptions(
    'db=s'    => \my $db,
    'kml=s'   => \my $kml,
    'start=s' => \my $start,
    'end=s'   => \my $end,
);

$db  //= './images.db';
$kml //= './images.kml';

my $dbh    = _db( $db );
my $coords = _get_coords( $dbh, $start, $end );
_create_kml( $coords, $kml );

sub _create_kml ( $coords, $kml ) {
    say "create kml...";
    my $dom  = XML::LibXML::Document->new( '1.0', 'utf-8' );
    my $root = $dom->createElementNS( 'http://earth.google.com/kml/2.1', 'kml' );
    my $doc  = $dom->createElement('Document');

    my $place_cnt = 1;
    for my $image_coord ( $coords->@* ) {
        my $place = $dom->createElement('Placemark');
        $place->setAttribute( 'id', 'place_' . $place_cnt++ );

        my $name = $dom->createElement('nameription');
        $name->appendText( "#" . $place_cnt-1 ); 
        $place->appendChild( $name );

        my $desc = $dom->createElement('description');
        $desc->appendText( sprintf "%s (%s)", $image_coord->@{qw/filename create_orig/} );
        $place->appendChild( $desc );

        my $point = $dom->createElement('Point');
        $place->appendChild( $point );

        my $coord = $dom->createElement( 'coordinates');
        $coord->appendText( join ',', $image_coord->@{qw/gps_longitude gps_latitude/} );
        $point->appendChild( $coord );

        $doc->appendChild( $place );
    }

    $root->appendChild( $doc );

    $dom->setDocumentElement( $root );
    my $kml_content = $dom->toString;

    open my $fh, '>', $kml or croak $!;
    print $fh $kml_content or croak $!;
    close $fh              or croak $!;
}

sub _get_coords ( $dbh, $start, $end ) {
    my $sql = q~
        SELECT
            filename, gps_latitude, gps_longitude, gps_time, create_orig
        FROM
            image_data
    ~;

    my (@where,@bind);
    if ( $start ) {
        push @where, 'gps_time > ?';
        push @bind,  $start;
    } 

    if ( $end ) {
        push @where, 'gps_time < ?';
        push @bind,  $end;
    } 

    $sql .= 'WHERE ' . join( ' AND ', @where ) if @where;
    $sql .= ' ORDER BY gps_time ASC';

    my $sth = $dbh->prepare( $sql );
    $sth->execute( @bind );

    my @coords;
    while ( my @row = $sth->fetchrow_array ) {
        for my $index (1,2) {
            my ($degree, $minute, $second, $direction) = $row[$index] =~ m{
                ([0-9]+) \s+ deg \s+   # degree
                ([0-9]+)' \s+          # minute
                ([0-9]+\.[0-9]+)" \s+  # seconds
                ([NESW])               # direction
            }xms;

            $row[$index] = sprintf "%s%.8f",
                ( $direction =~ m{[SW]} ? '-' : '' ),
                ( $degree + ( $minute / 60 ) + ( $second / 3600 ) )
            ;
        }

        push @coords, {
            filename      => $row[0],
            gps_latitude  => $row[1],
            gps_longitude => $row[2],
            gps_time      => $row[3],
            create_orig   => $row[4],
        };
    }

    return \@coords;
}

sub _db ( $db ) {
    if ( !-f $db ) {
        croak 'Database does not exist: ' . $db;
    }

    my $dbh = DBI->connect( 'DBI:SQLite:' . $db );

    return $dbh;
}
