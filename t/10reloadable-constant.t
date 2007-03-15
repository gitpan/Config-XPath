#!/usr/bin/perl -w

use strict;

use Test::More tests => 6;
use Test::Exception;

use_ok( "Config::XPath::Reloadable" );

throws_ok( sub { Config::XPath::Reloadable->new( xml => "<data>foo</data>" ) },
           "Config::XPath::Exception",
           'reloadable with no filename throws exception' );

my $c;

$c = Config::XPath::Reloadable->new( filename => "t/data.xml" );

my $s;

$s = $c->get_string( "/data/aaa/bbb" );
is( $s, "Content", 'content' );

my $aref;

$aref = $c->get_attrs( "/data/ccc/dd[\@name=\"one\"]" );
ok( defined $aref, 'attributes defined $aref' );
is_deeply( $aref, { '+' => "dd", name => "one", value => "1" }, 'attributes values' );

my @l;

@l = $c->get_list( "/data/ccc/dd/\@name" );
is_deeply( \@l, [ qw( one two ) ], 'list values' );
