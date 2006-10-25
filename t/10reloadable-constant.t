#!/usr/bin/perl -w

use strict;

use Test::More tests => 5;

use_ok( "Config::XPath::Reloadable" );

my $c;

$c = Config::XPath::Reloadable->new( "t/data.xml" );

my $s;

$s = $c->get_config_string( "/data/aaa/bbb" );
is( $s, "Content", 'content' );

my $aref;

$aref = $c->get_config_attrs( "/data/ccc/dd[\@name=\"one\"]" );
ok( defined $aref, 'attributes defined $aref' );
is_deeply( $aref, { '+' => "dd", name => "one", value => "1" }, 'attributes values' );

my @l;

@l = $c->get_config_list( "/data/ccc/dd/\@name" );
is_deeply( \@l, [ qw( one two ) ], 'list values' );
