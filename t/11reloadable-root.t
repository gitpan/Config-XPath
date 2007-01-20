#!/usr/bin/perl -w

use strict;

use Test::More tests => 5;

use Config::XPath::Reloadable;

use File::Temp qw( tempfile );
use IO::Handle;

sub rewind($) { seek shift, 0, 0; }

my ( $conffile, $conffilename ) = tempfile();
defined $conffile or die "Could not open a tempfile for testing - $!";
$conffile->autoflush( 1 );

print $conffile <<EOC;
<config>
  <key>value here</key>
</config>
EOC

my $c;

$c = Config::XPath::Reloadable->new( $conffilename );
ok( defined $c, 'defined $c' );
is( ref $c, "Config::XPath::Reloadable", 'ref $c' );

my $s;

$s = $c->get_string( "/config/key" );
is( $s, "value here", 'initial content' );

rewind $conffile;

print $conffile <<EOC;
<config>
  <key>new value here</key>
</config>
EOC

$s = $c->get_string( "/config/key" );
is( $s, "value here", 'reread content' );

$c->reload();

$s = $c->get_string( "/config/key" );
is( $s, "new value here", 'changed content' );
