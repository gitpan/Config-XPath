#!/usr/bin/perl -w

use strict;

use Test::More tests => 10;
use Test::Exception;

use Config::XPath;

my $c;

$c = Config::XPath->new( filename => "t/data.xml" );
ok( defined $c, 'defined $c' );
is( ref $c, "Config::XPath", 'ref $c' );

my $mref;

$mref = $c->get_map( "/data/eee/ff", '@name', '.' );
ok( defined $mref, 'map defined $mref' );
is_deeply( $mref, { one => 1, two => 2 }, 'map value' );

$mref = $c->get_map( "/data/ccc/dd", '@value', 'i/@ord' );
ok( defined $mref, 'map defined $mref' );
is_deeply( $mref, { 1 => "first", 2 => "second" }, 'map value' );

$mref = $c->get_map( "/data/nonodeshere", '@name', '@value' );
ok( defined $mref, 'map defined $mref for no nodes' );
is_deeply( $mref, {}, 'map value for no nodes' );

throws_ok( sub { $mref = $c->get_map( "/data/aaa/bbb", '@name', '.' ) },
           'Config::XPath::ConfigNotFoundException',
           'get_config_map missing key throws exception' );

throws_ok( sub { $mref = $c->get_map( "/data/eee/ff", '@name', '@value' ) },
           'Config::XPath::ConfigNotFoundException',
           'get_config_map missing value throws exception' );
