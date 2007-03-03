#!/usr/bin/perl -w

use strict;

use Test::More tests => 13;

use Config::XPath;

my $c;

$c = Config::XPath->new( filename => "t/data.xml" );
ok( defined $c, 'defined $c' );
is( ref $c, "Config::XPath", 'ref $c' );

my $sub = $c->get_sub_config( "/data/ccc" );
ok( defined $sub, 'defined $sub' );
is( ref $sub, "Config::XPath", 'ref $sub' );

my ( $s, $aref, @l );

$s = $sub->get_string( "dd[\@name=\"one\"]/\@value" );
is( $s, "1", 'sub get_config_string' );

$aref = $sub->get_attrs( "dd[\@name=\"one\"]" );
is_deeply( $aref, { '+' => "dd", name => "one", value => "1" }, 'sub get_config_attrs' );

@l = $sub->get_list( "dd/\@name" );
is_deeply( \@l, [ qw( one two ) ], 'sub get_config_list' );

my @subs = $c->get_sub_config_list( "/data/ccc/dd" );
is( scalar @subs, 2, 'get_sub_config_list count' );
is( ref $subs[0], "Config::XPath", 'subconfig[0] ref type' );
is( ref $subs[1], "Config::XPath", 'subconfig[1] ref type' );

$sub = $subs[0];

$s = $sub->get_string( "\@name" );
is( $s, "one", 'subs[0] get_config_string' );

$aref = $sub->get_attrs( "i" );
is_deeply( $aref, { '+' => "i", ord => "first" }, 'subs[0] get_config_attrs' );

@l = $sub->get_list( "i" );
is_deeply( \@l, [ { '+' => "i", ord => "first" } ], 'subs[0] get_config_list' );
