#!/usr/bin/perl -w

use strict;

use Test::More tests => 3;

use Config::XPath;

use XML::Parser;
  
my $c;

$c = Config::XPath->new(
   parser => XML::Parser->new(),
   xml    => '<data><string>Value</string></data>',
);

ok( defined $c, 'defined $c' );
is( ref $c, "Config::XPath", 'ref $c' );

my $s;

$s = $c->get_string( "/data/string" );
is( $s, "Value", 'content from parser' );
