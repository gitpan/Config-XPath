#!/usr/bin/perl -w

use strict;

use Test::More tests => 3;

use Config::XPath;

my $c;

$c = Config::XPath->new( ioref => \*DATA );

ok( defined $c, 'defined $c' );
is( ref $c, "Config::XPath", 'ref $c' );

my $s;

$s = $c->get_string( "/data/string" );
is( $s, "Value", 'content from inline XML' );

__DATA__
<data>
  <string>Value</string>
</data>
